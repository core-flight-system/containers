#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <time.h>

#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <syslog.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#include <getopt.h>

/* the status/exit code from cFS when a poweron restart is commanded */
#define CFS_SYSTEM_RESTART_EXITCODE -42

/* amount of time cFS must run for in order to be considered a valid boot */
#define CFS_MINIMUM_RUN_TIME        15

/* max number of times to run the main loop */
/* this is only for rapid loops - if CFS_MINIMUM_RUN_TIME is met, the counter resets */
#define MAX_LOOP_COUNT        16

/* size of ring buffer for stdout, keep to a power of 2 */
#define BUFFER_RING_SIZE 256

const char LOGGER_DEFAULT_IDENT[] = "CFS";

typedef enum cfs_statuscode
{
    cfs_statuscode_failure = -1,
    cfs_statuscode_undefined = 0,
    cfs_statuscode_poweron_restart_req = 1,
    cfs_statuscode_processor_restart_req = 2
} cfs_statuscode_t;

static struct global
{
    bool verbose;
    bool should_daemonize;
    bool should_exit;
    bool should_reboot;
    bool should_chroot;

    pid_t current_child_pid;
    struct timespec child_fork_time;
    int child_exitstatus;
    int child_stdout;

    /* the extra byte ensures a null at the end of the buffer */
    char stdout_buffer[BUFFER_RING_SIZE + 1];
    size_t write_pos;
    size_t read_pos;
    char logger_ident[16];
    int logger_facility;

    int loop_count;

    const char *workdir_path;
    const char *pid_file;
    int pidfile_fd;
    char **reboot_argv;
    char **cfs_argv;
    int cfs_argc;
} global;

/*
** getopts parameter passing options string
*/
static const char *optString = "dvCp:r:i:f:w:?";

/*
** getopts_long long form argument table
*/
static struct option longOpts[] = {
    { "daemonize", no_argument,       NULL, 'd' },
    { "chroot",    no_argument,       NULL, 'C' },
    { "verbose",   no_argument,       NULL, 'v' },
    { "reboot",    required_argument, NULL, 'r' },
    { "pidfile",   required_argument, NULL, 'p' },
    { "ident",     required_argument, NULL, 'i' },
    { "facility",  required_argument, NULL, 'f' },
    { "workdir",   required_argument, NULL, 'w' },
    { "help",      no_argument,       NULL, '?' },
    { NULL,        no_argument,       NULL, 0   }
};

void fork_exec(char * const argv[])
{
    pid_t pid; 
    int pipefd[2];

    global.child_stdout = -1;
    global.current_child_pid = 0;

    /* create a pipe for stdout */
    /* [0] is for reading, [1] is for writing */
    if (pipe(pipefd) < 0)
    {
        perror("pipe");
        return;
    }

    pid = fork();

    if (pid == 0)
    {
        /* pidfile should not stay open in the child */
        if (global.pidfile_fd >= 0)
        {
            close (global.pidfile_fd);
        }

        /* map the write pipe to stdout */
        if (pipefd[1] != STDOUT_FILENO)
        {
            dup2(pipefd[1], STDOUT_FILENO);
            close(pipefd[1]);
        }
        close(pipefd[0]);

        /* send stderr to the same log */
        dup2(STDOUT_FILENO, STDERR_FILENO);

        /* child process - exec cFS from here */
        /* if execvp() works this does not return */
        execvp(argv[0], argv);

        /* as the fork() was successful this needs to exit */
        perror("execvp");
        exit(EXIT_FAILURE);
    }

    /* only the parent process gets here */
    /* parent never uses the write fd */
    close(pipefd[1]);
        
    if (pid < 0)
    {
        /* this means there was some failure to fork() */
        close(pipefd[0]);
        perror("fork");
    }
    else 
    {
        global.write_pos = 0;
        global.read_pos = 0;
        global.child_stdout = pipefd[0];
        global.child_exitstatus = 0;
        global.current_child_pid = pid;

        clock_gettime(CLOCK_MONOTONIC, &global.child_fork_time);
        if (global.verbose)
        {
            printf("launched %s, pid %d, time=%ld\n", argv[0], (int)pid, 
                (long)global.child_fork_time.tv_sec);
        }
    }
}

void write_child_stdout(void)
{
    size_t rd_idx;
    size_t wr_idx;
    size_t bufsz; 
    char *start_p;
    char *end_p;
    char *msg_p;
    char full_message[BUFFER_RING_SIZE + 1];

    /* check for newlines before updating wr_idx */
    while(true)
    {
        bufsz = global.write_pos - global.read_pos;
        if (bufsz == 0)
        {
            break;
        }

        rd_idx = global.read_pos % BUFFER_RING_SIZE;
        wr_idx = global.write_pos % BUFFER_RING_SIZE;

        start_p = &global.stdout_buffer[rd_idx];
        if (rd_idx < wr_idx)
        {
            /* simple case when no wrap */
            end_p = memchr(start_p, '\n', bufsz);
        }
        else
        {
            /* buffer has wrapped */
            end_p = memchr(start_p, '\n', BUFFER_RING_SIZE - rd_idx);
            if (end_p == NULL)
            {
                end_p = memchr(global.stdout_buffer, '\n', wr_idx);
            }
        }

        if (end_p == NULL)
        {
            /* nothing to write now */
            break;
        }

        msg_p = full_message;

        /* if the buffer wrapped this needs re-assembly */
        if (end_p < start_p)
        {
            bufsz = BUFFER_RING_SIZE - rd_idx;
            memcpy(msg_p, start_p, bufsz);
            start_p = &global.stdout_buffer[0];
            global.read_pos += bufsz;
            msg_p += bufsz;
        }

        if (end_p >= start_p)
        {
            bufsz = (end_p - start_p);
            memcpy(msg_p, start_p, bufsz);
            global.read_pos += bufsz + 1; /* to go past the newline */
            msg_p += bufsz;
        }

        if (msg_p != full_message)
        {
            *msg_p = 0; 

            /* it would be nice to propagate the log level from cFS into syslog,
             * but this is not known by the time it makes its way through stdout */
            syslog(LOG_NOTICE, "%s", full_message);
        }
    }

}

void read_child_stdout(void)
{
    size_t rd_idx;
    size_t wr_idx;
    size_t fill;
    size_t avail;
    ssize_t ret;
    char *start_p;
    char *end_p;

    fill = global.write_pos - global.read_pos;
    if (fill >= BUFFER_RING_SIZE)
    {
        /* buffer is maxed out, dump some data */
        global.read_pos += fill - (BUFFER_RING_SIZE / 2);
        fill = global.write_pos - global.read_pos;
    }

    /* the buffer is guaranteed to not be completely full */
    wr_idx = global.write_pos % BUFFER_RING_SIZE;
    rd_idx = global.read_pos % BUFFER_RING_SIZE;

    if (wr_idx < rd_idx)
    {
        avail = rd_idx - wr_idx;
    }
    else 
    {
        avail = BUFFER_RING_SIZE - wr_idx;
    }

    ret = read(global.child_stdout, &global.stdout_buffer[wr_idx], avail);
    if (ret < 0)
    {
        perror("read");
    }

    if (ret <= 0)
    {
        /* zero generally means the other side has closed the pipe */
        close(global.child_stdout);
        global.child_stdout = -1;
    }
    else
    {
        /* nonzero amount of data input */
        global.write_pos += ret;

        /* this also means the child is alive and well, so reset the loop count */
        global.loop_count = 0;
    }
}

void check_stdout(void)
{
    int ret;
    struct pollfd pfd;

    pfd.events = POLLIN;
    pfd.revents = 0;
    pfd.fd = global.child_stdout;

    ret = poll(&pfd, 1, 500);
    if (ret > 0)
    {
        if (pfd.revents & POLLIN)
        {
            read_child_stdout();
        }
        if (pfd.revents & POLLERR)
        {
            /* just invoke error handling path */
            if (global.verbose)
            {
                printf("poll error on child pipe");
            }
            ret = -1;
        }
    }

    if (ret < 0)
    {
        perror("poll");
        close(global.child_stdout);
        global.child_stdout = -1;
    }
    else if (ret == 0)
    {
        /* timeout -- reset the loop counter  */
        /* a silent child is fine, no problem here */
        global.loop_count = 0;
    }
}

void wait_child(void)
{
    pid_t pid; 
    int opts;
    int stat;

    if (global.child_stdout >= 0)
    {
        check_stdout();
        
        /* check if anything can be forwarded */
        write_child_stdout();

        opts = WNOHANG;
    }
    else 
    {
        if (global.verbose)
        {
            printf("about to wait() on child=%d\n", (int)global.current_child_pid);
        }
        opts = 0;
    }

    /* check if there are any child status change events */
    pid = waitpid(-1, &stat, opts);

    if (pid < 0)
    {
        perror("wait");
    }
    else if (pid == global.current_child_pid)
    {
        if (WIFEXITED(stat))
        {
            /* child is no longer running, check the exit code */
            global.current_child_pid = 0;

            /* positive exitstatus means exit */
            global.child_exitstatus = WEXITSTATUS(stat);
        }
        else if (WIFSIGNALED(stat))
        {
            /* child is no longer running, this means it caught a signal */
            global.current_child_pid = 0;

            /* negative exitstatus means signal */
            global.child_exitstatus = -1 * WTERMSIG(stat);
        }
        else 
        {
            /* this could be a job control signal, but child is still alive */
            if (global.verbose)
            {
                printf("wait() status=%d (ignoring)\n", stat);
            }
        }

        if (global.verbose)
        {
            printf("wait() returned child=%d, scrubbed exitstatus=%d\n", (int)pid, 
                (int)global.child_exitstatus);
        }
    }

    /* clean up the file handle if the child exited */
    if (global.current_child_pid == 0 && global.child_stdout >= 0)
    {
        close(global.child_stdout);
        global.child_stdout = -1;
    }
}

void check_rapid_loop(void)
{
    struct timespec now;

    if (global.loop_count == 0)
    {
        /* nothing to do first time through */
        return;
    }

    if (global.loop_count > MAX_LOOP_COUNT)
    {
        /* something is broken, looping again will not fix it */
        if (global.verbose)
        {
            printf("error: looping detected, misconfiguration?\n");
        }
        global.should_exit = 1;
    }
    else if (global.current_child_pid <= 0)
    {
        /* cFS is not running, check the clock */
        /* get the time elapsed between fork and now */
        clock_gettime(CLOCK_MONOTONIC, &now);

        /* if CFS ran for some time then reset the loop counter */
        /* this is just ignoring nanoseconds, its just a rough estimate */
        if ((now.tv_sec - global.child_fork_time.tv_sec) >= CFS_MINIMUM_RUN_TIME)
        {
            global.loop_count = 0;
        }
        else 
        {
            if (global.verbose) 
            {
                printf("short runtime detected, retrying after pause\n");
            }
            /* will loop again, but slow down a bit */
            ++now.tv_sec;
            clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &now, NULL);
        }
    }
}

void write_pid_file(pid_t pid)
{    
    char pid_msg[16];

    if (global.pid_file != NULL)
    {
        global.pidfile_fd = open(global.pid_file, O_WRONLY|O_CREAT|O_TRUNC, 0644);

        if (global.pidfile_fd < 0)
        {
            perror(global.pid_file);
            exit(EXIT_FAILURE);
        }

        snprintf(pid_msg, sizeof(pid_msg), "%u\n", (unsigned int)pid);
        write(global.pidfile_fd, pid_msg, strlen(pid_msg));
        fsync(global.pidfile_fd);

        /* note - intentionally leaving fd open for future call to unlinkat() */
    }
}

void remove_pid_file()
{    
    const char *relative_dir;

    if (global.pid_file != NULL)
    {
        if (global.pidfile_fd >= 0)
        {
            /* use "unlinkat" and pass a relative dir, such that this should still work after chroot */
            relative_dir = strrchr(global.pid_file, '/');
            if (relative_dir == NULL)
            {
                relative_dir = global.pid_file;                
            }
            else 
            {
                ++relative_dir;
            }

            unlinkat(global.pidfile_fd, relative_dir, 0);
        }
        else 
        {
            /* just use regular unlink */
            unlink(global.pid_file);
        }
    }
}

void sigtermint_handler(int sig, siginfo_t *si, void *arg)
{
}

void setup_signals(void)
{
    struct sigaction act;

    memset(&act, 0, sizeof(act));
    act.sa_handler = stopContinue;
    sigaction(SIGINT, &act, NULL);    
}

void do_chroot(void)
{
    char workdir[128];
    char *wd;

    wd = getcwd(workdir, sizeof(workdir));

    if (wd == NULL)
    {
        perror("getcwd");
        exit(EXIT_FAILURE);
    }

    if (chroot(workdir) < 0)
    {
        fprintf(stderr, "chdir(%s): %s\n", workdir, strerror(errno));
        exit(EXIT_FAILURE);
    }
}

void daemonize(void)
{
    pid_t pid;

    pid = fork();

    if (pid < 0) 
    {
        perror("fork failed");
        exit(EXIT_FAILURE);
    }

    if (pid > 0) 
    {
        /* Parent process exits */
        exit(EXIT_SUCCESS);
    }

    /* Child process continues */
    /* become the session leader */
    if (setsid() < 0) 
    {
        perror("setsid failed");
        exit(EXIT_FAILURE);
    }

    /* only the child process returns to the caller from here */
    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);
}

void show_help(void)
{
    fprintf(stderr, "Usage: cfs-manager [options] <core-executable>\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Available options:\n");
    fprintf(stderr, "  -d|--daemonize : Fork into background when starting cFS\n");
    fprintf(stderr, "  -v|--verbose   : Increase output level for debugging\n");
    fprintf(stderr, "  -p|--pidfile   : Create a PID file for the cFS process\n");
    fprintf(stderr, "  -w|--workdir   : Call chroot() with workdir path before starting cFS\n");
    fprintf(stderr, "  -C|--chroot    : Call chroot() with workdir path before starting cFS\n");
    fprintf(stderr, "  -r|--reboot    : Command to execute if a reboot is commanded from cFS\n");
    fprintf(stderr, "  -i|--indent    : Identifier string to use for syslog (cfs)\n");
    fprintf(stderr, "  -f|--facility  : Facility value to use for syslog (user)\n");
    fprintf(stderr, "  -?|--help      : Show this help\n");
    fprintf(stderr, "\n");

    exit (EXIT_FAILURE);
}

void parse_options(int argc, char * const argv[])
{
    int   opt;
    int   longIndex;

    /* Process the arguments with getopt_long() */
    while(true)
    {
        opt = getopt_long(argc, argv, optString, longOpts, &longIndex);
        if (opt < 0)
        {
            break;
        }

        switch(opt)
        {
        case 'D':
            global.should_daemonize = true;
            break;

        case 'v':
            global.verbose = true;
            break;

        case 'C':
            global.should_chroot = true;
            break;

        case 'p':
            global.pid_file = optarg;
            break;

        case 'w':
            global.workdir_path = optarg;
            break;

        case 'r':
            global.reboot_argv = malloc(sizeof(char *) * 2);
            if (global.reboot_argv == NULL)
            {
                perror("malloc");
            }
            else 
            {
                global.reboot_argv[0] = strdup(optarg);
                global.reboot_argv[1] = NULL;
            }
            break;

        case 'i':
            strncpy(global.logger_ident, optarg, sizeof(global.logger_ident) - 1);
            break;

        case 'f':
            if (strcmp(optarg, "user") == 0)
            {
                global.logger_facility = LOG_USER;
            }
            else if (strcmp(optarg, "daemon") == 0)
            {
                global.logger_facility = LOG_DAEMON;
            }
            else if (strncmp(optarg, "local", 5) == 0)
            {
                switch(optarg[5])
                {
                    case '0':
                        global.logger_facility = LOG_LOCAL0;
                        break;

                    case '1':
                        global.logger_facility = LOG_LOCAL1;
                        break;

                    case '2':
                        global.logger_facility = LOG_LOCAL2;
                        break;

                    case '3':
                        global.logger_facility = LOG_LOCAL3;
                        break;

                    case '4':
                        global.logger_facility = LOG_LOCAL4;
                        break;

                    case '5':
                        global.logger_facility = LOG_LOCAL5;
                        break;

                    case '6':
                        global.logger_facility = LOG_LOCAL6;
                        break;

                    case '7':
                        global.logger_facility = LOG_LOCAL7;
                        break;
                }
            }
            if (global.logger_facility == 0)
            {
                fprintf(stderr, "Invalid logger facility.  Supported values are user, daemon, and local[0-7]\n");
                show_help();
            }
            break;

        default:
            show_help();
            break;
        }
    }

    /* defaults if value is not specified on command line */
    if (global.logger_facility == 0)
    {
        global.logger_facility = LOG_USER;
    }
    
    if (global.logger_ident[0] == 0)
    {
        strncpy(global.logger_ident, LOGGER_DEFAULT_IDENT, sizeof(global.logger_ident) - 1);
    }

    /* file name of cFS binary is required, it must be the first remaining arg */
    if (optind >= argc)
    {
        fprintf(stderr, "Error: missing cFS command argument\n");
        show_help(); /* does not return */
    }

    global.cfs_argv = malloc(sizeof(char *) * (1 + argc - optind));
    if (global.cfs_argv == NULL)
    {
        perror("malloc");
        exit(EXIT_FAILURE);
    }

    while (optind < argc)
    {
        global.cfs_argv[global.cfs_argc] = strdup(argv[optind]);
        ++global.cfs_argc;
        ++optind;
    }

    /* this is the extra entry */
    global.cfs_argv[global.cfs_argc] = NULL;
}

int main(int argc, char *const argv[])
{
    cfs_statuscode_t sc; 

    sc = cfs_statuscode_undefined;
    memset(&global, 0, sizeof(global));

    /* since 0 is a valid descriptor, file descriptors need to be set to -1 */
    global.pidfile_fd = -1;
    global.child_stdout = -1;

    parse_options(argc, argv);

    /* open syslog and write pidfile before doing chroot, if indicated */
    openlog(global.logger_ident, LOG_NDELAY, global.logger_facility);

    write_pid_file(getpid());

    if (global.workdir_path != NULL)
    {
        if (chdir(global.workdir_path) < 0)
        {
            fprintf(stderr, "chdir(%s): %s\n", global.workdir_path, strerror(errno));
            exit(EXIT_FAILURE);
        }
    }

    if (global.should_chroot)
    {
        do_chroot();
    }

    if (global.should_daemonize)
    {
        /* note: the current process exits from here */
        /* only the child process returns */
        daemonize();
    }

    while(!global.should_exit)
    {
        if (global.current_child_pid > 0)
        {
            /* wait for the child to have some action */
            wait_child();
        }
        else if (global.child_exitstatus == CFS_SYSTEM_RESTART_EXITCODE)
        {
            /* request a full system reboot */
            global.should_exit = true;
            global.should_reboot = true;

            if (global.verbose)
            {
                printf("cFS requested system reboot\n");
            }
        }
        else 
        {
            /* fork a new instance of cFS */
            fork_exec(global.cfs_argv);
        }

        /* check that cFS is actually starting */
        /* in case this starts rapidly looping, this breaks the cycle */
        check_rapid_loop();

        ++global.loop_count;
    }

    /* if a reboot was requested, then kick of the reboot script */
    if (global.should_reboot && global.reboot_argv) 
    {
        fork_exec(global.reboot_argv);
    }

    /* try to wait on any other child processes */
    global.loop_count = 0;
    while (global.loop_count < MAX_LOOP_COUNT &&
            global.current_child_pid > 0)
    {
        wait_child();
        ++global.loop_count;
    }

    return EXIT_SUCCESS;
}