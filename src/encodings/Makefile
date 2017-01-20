include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${ENCODINGS_LIB_A}
STATIC_LIB_NOINST = ${ENCODINGS_A}

SRCS = ${ENCODINGS_SRCS}

INCLUDES = ${SRCS:.m=.h}

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../runtime -I../exceptions -DOF_COMPILING_OBJFW
