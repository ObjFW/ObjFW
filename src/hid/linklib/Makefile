include ../../../extra.mk

STATIC_LIB = libobjfwhid.library.a
STATIC_AMIGA_LIB = libobjfwhid.library.amigalib.a
SRCS = init.m		\
       linklib.m

include ../../../buildsys.mk

CPPFLAGS += -I.. -I../.. -I../../.. -I../../runtime \
	    -DOBJFWHID_AMIGA_LIB=\"${OBJFWHID_AMIGA_LIB}\"		\
	    -DOBJFWHID_LIB_MINOR=${OBJFWHID_LIB_MINOR}
AMIGA_LIB_CFLAGS += -DOF_AMIGA_LIB
