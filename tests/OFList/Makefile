PROG_NOINST = oflist
SRCS = OFList.m

include ../../buildsys.mk

CPPFLAGS += -I../../src
LIBS += -lobjc -L../../src -lobjfw

all: ${PROG_NOINST}
	LD_LIBRARY_PATH=../../src \
	DYLD_LIBRARY_PATH=../../src \
	./${PROG_NOINST}
