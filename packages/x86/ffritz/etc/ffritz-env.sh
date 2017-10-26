# FFINSTDIR is either in  /var/media/ftp/ (if atom fs is unmodified) or
# /usr/local (if package is intergrated into atom squashfs)
#
EXEC_DIR=$( readlink -f $( dirname -- "$0" ) )
export FFINSTDIR=`cd $EXEC_DIR/..; pwd`
export FFRITZ_HOME=/var/media/ftp/ffritz
export TERMINFO=/usr/share/terminfo
export TERM=vt220
PATH=$PATH:$FFINSTDIR/bin
FFLOG=/var/log/ffritz.log
