include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${RUNTIME_LIB_A}
STATIC_LIB_NOINST = ${RUNTIME_A}

SRCS = category.m		\
       class.m			\
       hashtable.m		\
       init.m			\
       lookup.m			\
       lookup-amd64-elf.S	\
       lookup-x86-elf.S		\
       property.m		\
       protocol.m		\
       selector.m		\
       sparsearray.m		\
       static-instances.m	\
       synchronized.m		\
       threading.m
INCLUDES = runtime.h

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..
AS = ${OBJC}
ASFLAGS = ${CPPFLAGS}
LD = ${OBJC}
