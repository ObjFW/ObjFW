include ../../extra.mk

STATIC_LIB = libobjfw.library.a
STATIC_AMIGA_LIB = libobjfw.library.amigalib.a
SRCS = init.m		\
       linklib.m

include ../../buildsys.mk

CPPFLAGS += -I.. -I../.. -I../exceptions -I../runtime	\
	    -DOBJFW_AMIGA_LIB=\"${OBJFW_AMIGA_LIB}\"	\
	    -DOBJFW_LIB_MINOR=${OBJFW_LIB_MINOR}
