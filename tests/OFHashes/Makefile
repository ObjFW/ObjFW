PROG_NOINST = ofhashes
SRCS = OFHashes.m

include ../../buildsys.mk

CPPFLAGS += -I../../src
LIBS += -lobjc -L../../src -lobjfw

.PHONY: run

all: run
run: ${PROG_NOINST}
	rm -f libobjfw.so.1 libobjfw.dylib
	ln -s ../../src/libobjfw.so libobjfw.so.1
	ln -s ../../src/libobjfw.so libobjfw.so.1.0
	ln -s ../../src/libobjfw.dylib libobjfw.dylib
	LD_LIBRARY_PATH=. \
	DYLD_LIBRARY_PATH=. \
	./${PROG_NOINST}
	rm -f libobjfw.so.1 libobjfw.so.1.0 libobjfw.dylib
