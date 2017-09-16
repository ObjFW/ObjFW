include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${INVOCATION_LIB_A}
STATIC_LIB_NOINST = ${INVOCATION_A}

SRCS = call.S	\
       invoke.m

include ../../buildsys.mk

ASFLAGS += -I../.. -I..
OBJCFLAGS += -I../.. -I.. -I../exceptions -I../runtime
