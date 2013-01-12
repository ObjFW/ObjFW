include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${RUNTIME_LIB_A}
STATIC_LIB_NOINST = ${RUNTIME_A}

SRCS = arc.m			\
       category.m		\
       class.m			\
       exception.m		\
       hashtable.m		\
       init.m			\
       lookup.m			\
       ${LOOKUP_S}		\
       property.m		\
       protocol.m		\
       selector.m		\
       sparsearray.m		\
       static-instances.m	\
       synchronized.m		\
       ${USE_SRCS_THREADS}
SRCS_THREADS = threading.m
INCLUDES = runtime.h

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..
LD = ${OBJC}
