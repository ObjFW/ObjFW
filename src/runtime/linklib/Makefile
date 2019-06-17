include ../../../extra.mk

STATIC_LIB = libobjfwrt.library.a
SRCS = linklib.m

include ../../../buildsys.mk

CPPFLAGS += -I..  -I../..  -I../../..				\
	    -DOBJC_COMPILING_AMIGA_LINKLIB			\
	    -DOBJFWRT_AMIGA_LIB=\"${OBJFWRT_AMIGA_LIB}\"	\
	    -DOBJFWRT_LIB_MINOR=${OBJFWRT_LIB_MINOR}
LD = ${OBJC}
