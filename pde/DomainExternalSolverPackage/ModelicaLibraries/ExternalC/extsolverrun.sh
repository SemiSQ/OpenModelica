export RHEOLEFDIR="/usr/local/rheolef-4.74-shared"
export PATH="$PATH:$RHEOLEFDIR/bin:$RHEOLEFDIR/lib"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$RHEOLEFDIR/lib"
export MANPATH="$MANPATH:$RHEOLEFDIR/man"
export RHEOLEF_MODPATH="$RHEOLEFDIR/lib/rheolef/modules"
export RHEOLEF_LIBDIR="$RHEOLEFDIR/lib"
export PATH="$PATH:$RHEOLEF_MODPATH/form"

extsolver $* 
