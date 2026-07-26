include ../../../extra.mk

STATIC_LIB = libobjfwtls.library.a
STATIC_AMIGA_LIB = libobjfwtls.library.amigalib.a
SRCS = init.m		\
       linklib.m

include ../../../buildsys.mk

CPPFLAGS += -I.. -I../.. -I../../.. -I../../runtime \
	    -DOBJFWTLS_AMIGA_LIB=\"${OBJFWTLS_AMIGA_LIB}\"		\
	    -DOBJFWTLS_LIB_MINOR=${OBJFWTLS_LIB_MINOR}
AMIGA_LIB_CFLAGS += -DOF_AMIGA_LIB
