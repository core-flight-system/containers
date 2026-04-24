
# This gives the full POSIX 2008 API
CFLAGS += -D_XOPEN_SOURCE=700

SOURCES = cfs-manager.c

.PHONY: all clean

all: cfs-manager
clean:
	rm -f cfs-manager cfs-manager.o

cfs-manager: $(SOURCES:%.c=%.o)
	$(CC) $(CFLAGS) -o $(@) $(^) 

%.o: %c
	$(CC) $(CFLAGS) -o $(@) -c $(<) 

