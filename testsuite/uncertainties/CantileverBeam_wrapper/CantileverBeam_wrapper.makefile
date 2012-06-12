#
#  Makefile
#

# the wrapper name has the name of the model
WRAPPER_NAME=CantileverBeam_wrapper

DEFINES=-DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE=\"${WRAPPER_NAME}\" \
-DVERSION=\"0.0\" -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 \
-DHAVE_MEMORY_H=1 -DHAVE_STRINGS_H=1 -DHAVE_INTTYPES_H=1 -DHAVE_STDINT_H=1 -DHAVE_UNISTD_H=1 -DHAVE_DLFCN_H=1 -DHAVE_PTHREAD_H=1

CFLAGS = -g -O2 -I. -Ic:/openturns/include/openturns -I/cluster/opt/mingw-3.4.5/opt/libxml2/include/libxml2 -I/cluster/opt/mingw-3.4.5/opt/regex/include
LDFLAGS = -L/c/mingw/lib -L/c/MinGW/lib \
-Lc:/openturns/lib/bin -L/cluster/opt/mingw-3.4.5/opt/libxml2/lib \
-L/cluster/opt/mingw-3.4.5/opt/regex/lib -L/c/openturns/bin \
/c/OpenTURNS/lib/openturns/libOT.dll.a -lOTbind-0 \
/c/mingw/lib/libxml2.dll.a /c/mingw/lib/libgnurx.dll.a \
/c/mingw/lib/libpthreadGC2.dll.a -Wl,--image-base=0x10000000 -Wl,--out-implib,${WRAPPER_NAME}.dll.a

all: ${WRAPPER_NAME}.dll

read_matlab4.o : read_matlab4.c read_matlab4.h
	gcc -o read_matlab4.o -c read_matlab4.c $(DEFINES) $(CFLAGS) 

${WRAPPER_NAME}.o: wrapper.c model_name.h wrapper_name.h 
	gcc -o ${WRAPPER_NAME}.o -c wrapper.c $(DEFINES) $(CFLAGS) 

${WRAPPER_NAME}.dll: ${WRAPPER_NAME}.o read_matlab4.o
	gcc $(DEFINES) -shared  ${WRAPPER_NAME}.o read_matlab4.o -o ${WRAPPER_NAME}.dll $(LDFLAGS)

clean: 
	rm -f ${WRAPPER_NAME}.o ${WRAPPER_NAME}.dll ${WRAPPER_NAME}.dll.a read_matlab4.o
