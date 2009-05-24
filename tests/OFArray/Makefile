PROG_NOINST = ofarray${PROG_SUFFIX}
SRCS = OFArray.m

include ../../buildsys.mk
include ../../extra.mk

CPPFLAGS += -I../../src -I../..
LIBS := -L../../src -lobjfw ${LIBS}

.PHONY: run

all: run
run: ${PROG_NOINST}
	rm -f libobjfw.so.0 libobjfw.so.0.1 libobjfw.dll libobjfw.dylib
	ln -s ../../src/libobjfw.so libobjfw.so.0
	ln -s ../../src/libobjfw.so libobjfw.so.0.1
	ln ../../src/libobjfw.dll libobjfw.dll
	ln -s ../../src/libobjfw.dylib libobjfw.dylib
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.0 libobjfw.so.0.1 libobjfw.dll libobjfw.dylib; \
	exit $$EXIT
