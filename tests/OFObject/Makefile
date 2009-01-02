PROG_NOINST = ofobject${PROG_SUFFIX}
SRCS = OFObject.m

include ../../buildsys.mk
include ../../extra.mk

CPPFLAGS += -I../../src -I../..
LIBS := -L../../src -lobjfw ${LIBS}

.PHONY: run

all: run
run: ${PROG_NOINST}
	rm -f libobjfw.so.1 libobjfw.so.1.0 libobjfw.dylib
	ln -s ../../src/libobjfw.so libobjfw.so.1
	ln -s ../../src/libobjfw.so libobjfw.so.1.0
	ln -s ../../src/libobjfw.dll libobjfw.dll
	ln -s ../../src/libobjfw.dylib libobjfw.dylib
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.1 libobjfw.so.1.0 libobjfw.dll libobjfw.dylib; \
	exit $$EXIT
