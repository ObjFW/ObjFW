include ../../extra.mk

PROG_NOINST = objc_sync${PROG_SUFFIX}
SRCS = test.m

include ../../buildsys.mk

post-all: ${RUN_TESTS}

.PHONY: run
run:
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}
	rm -f libobjfw.dll libobjfw.${OBJFW_LIB_MAJOR}.dylib
	rm -f libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR}
	rm -f libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR_MINOR}
	rm -f libobjfw_rt.dll libobjfw_rt.${OBJFW_RT_LIB_MAJOR}.dylib
	if test -f ../../src/libobjfw.so; then \
		${LN_S} ../../src/libobjfw.so libobjfw.so.${OBJFW_LIB_MAJOR}; \
		${LN_S} ../../src/libobjfw.so \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	elif test -f ../../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; then \
		${LN_S} ../../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../../src/libobjfw.dll; then \
		${LN_S} ../../src/libobjfw.dll libobjfw.dll; \
	fi
	if test -f ../../src/libobjfw.dylib; then \
		${LN_S} ../../src/libobjfw.dylib \
		    libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	fi
	if test -f ../../src/runtime/libobjfw_rt.so; then \
		${LN_S} ../../src/runtime/libobjfw_rt.so \
		    libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR}; \
		${LN_S} ../../src/runtime/libobjfw_rt.so \
		    libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR_MINOR}; \
	elif test -f ../../src/runtime/libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR_MINOR}; then \
		${LN_S} ../../src/runtime/libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR_MINOR} libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../../src/runtime/libobjfw_rt.dll; then \
		${LN_S} ../../src/runtime/libobjfw_rt.dll libobjfw_rt.dll; \
	fi
	if test -f ../../src/runtime/libobjfw_rt.dylib; then \
		${LN_S} ../../src/runtime/libobjfw_rt.dylib \
		    libobjfw_rt.${OBJFW_RT_LIB_MAJOR}.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	${WRAPPER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} libobjfw.dll; \
	rm -f libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	rm -f libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR}; \
	rm -f libobjfw_rt.so.${OBJFW_RT_LIB_MAJOR_MINOR} libobjfw_rt.dll; \
	rm -f libobjfw_rt.${OBJFW_RT_LIB_MAJOR}.dylib; \
	exit $$EXIT

CPPFLAGS += -I../../src/runtime -I../../src -I../..
LIBS := -L../../src -lobjfw ${LIBS}
LD = ${OBJC}
