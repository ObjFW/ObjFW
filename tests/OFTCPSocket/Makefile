PROG_NOINST = oftcpsocket${PROG_SUFFIX}
SRCS = OFTCPSocket.m

include ../../buildsys.mk
include ../../extra.mk

CPPFLAGS += -I../../src -I../..
LIBS := -L../../src -lobjfw ${LIBS}

.PHONY: run

all: run
run: ${PROG_NOINST}
	rm -f libobjfw.so.0 libobjfw.so.0.1 libobjfw.dll libobjfw.dylib
	if test -f ../../src/libobjfw.so; then \
		ln -s ../../src/libobjfw.so libobjfw.so.0; \
		ln -s ../../src/libobjfw.so libobjfw.so.0.1; \
	fi
	if test -f ../../src/libobjfw.dll; then \
		ln ../../src/libobjfw.dll libobjfw.dll; \
	fi
	if test -f ../../src/libobjfw.dylib; then \
		ln -s ../../src/libobjfw.dylib libobjfw.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.0 libobjfw.so.0.1 libobjfw.dll libobjfw.dylib; \
	exit $$EXIT
