include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${RUNTIME_LIB_A}
STATIC_LIB_NOINST = ${RUNTIME_A}

SRCS = category.m		\
       class.m			\
       hashtable.m		\
       init.m			\
       lookup.m			\
       protocol.m		\
       selector.m		\
       sparsearray.m		\
       static-instances.m	\
       threading.m		\
       asm/amd64-elf/lookup.S	\
       asm/x86-elf/lookup.S
INCLUDES = runtime.h

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..
AS = ${OBJC}
ASFLAGS = ${CPPFLAGS}
LD = ${OBJC}
