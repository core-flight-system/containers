#
# Build all docker images. 
#

GIT_DESCRIPTION=`git describe --dirty`

for x in rtems*; 
do
	docker build -t $x:$GIT_DESCRIPTION $x
done
