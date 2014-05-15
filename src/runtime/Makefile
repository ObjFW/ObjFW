include ../../extra.mk

SUBDIRS = lookup-asm

STATIC_PIC_LIB_NOINST = ${RUNTIME_LIB_A}
STATIC_LIB_NOINST = ${RUNTIME_A}

SRCS = arc.m			\
       category.m		\
       class.m			\
       dtable.m			\
       exception.m		\
       hashtable.m		\
       init.m			\
       lookup.m			\
       property.m		\
       protocol.m		\
       selector.m		\
       sparsearray.m		\
       static-instances.m	\
       synchronized.m		\
       ${USE_SRCS_THREADS}
SRCS_THREADS = threading.m
INCLUDES = runtime.h

OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_A}
LIB_OBJS_EXTRA = ${LOOKUP_ASM_LOOKUP_ASM_LIB_A}

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..
LD = ${OBJC}
