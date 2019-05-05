include ../../../extra.mk

STATIC_LIB = libobjfw_rt.library.a
SRCS = linklib.m

include ../../../buildsys.mk

CPPFLAGS += -I..  -I../..  -I../../..				\
	    -DOBJC_COMPILING_AMIGA_LINKLIB			\
	    -DOBJFW_RT_AMIGA_LIB=\"${OBJFW_RT_AMIGA_LIB}\"	\
	    -DOBJFW_RT_LIB_MINOR=${OBJFW_RT_LIB_MINOR}
LD = ${OBJC}
