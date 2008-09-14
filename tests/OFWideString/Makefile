PROG_NOINST = ofwidestring
SRCS = OFWideString.m

include ../../buildsys.mk

CPPFLAGS += -I../../src
LIBS += -lobjc -L../../src -lobjfw

.PHONY: run

all: run
run: ${PROG_NOINST}
	LD_PRELOAD=../../src/libobjfw.so \
	DYLD_LIBRARY_PATH=../../src \
	./${PROG_NOINST}
