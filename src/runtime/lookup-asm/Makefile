include ../../../extra.mk

STATIC_PIC_LIB_NOINST = ${LOOKUP_ASM_LIB_A}
STATIC_AMIGA_LIB_NOINST = ${LOOKUP_ASM_AMIGALIB_A}
STATIC_LIB_NOINST = ${LOOKUP_ASM_A}

SRCS = lookup-asm.S

include ../../../buildsys.mk

ASFLAGS += -I../../.. -I../..
ASFLAGS_lookup-asm.amigalib.o += -DOF_BASEREL
