include ../extra.mk

PROG_NOINST = gen_tables${PROG_SUFFIX}
SRCS = TableGenerator.m

.PHONY: run
run: all
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}
	rm -f libobjfw.dll libobjfw.${OBJFW_LIB_MAJOR}.dylib
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR}
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}
	rm -f libobjfwrt.dll libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib
	rm -f ${OBJFWRT_AMIGA_LIB}
	if test -f ../src/libobjfw.so; then \
		${LN_S} ../src/libobjfw.so libobjfw.so.${OBJFW_LIB_MAJOR}; \
		${LN_S} ../src/libobjfw.so \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	elif test -f ../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; then \
		${LN_S} ../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../src/libobjfw.dll; then \
		${LN_S} ../src/libobjfw.dll libobjfw.dll; \
	fi
	if test -f ../src/libobjfw.dylib; then \
		${LN_S} ../src/libobjfw.dylib \
		    libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	fi
	if test -f ../src/runtime/libobjfwrt.so; then \
		${LN_S} ../src/runtime/libobjfwrt.so \
		    libobjfwrt.so.${OBJFWRT_LIB_MAJOR}; \
		${LN_S} ../src/runtime/libobjfwrt.so \
		    libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; \
	elif test -f ../src/runtime/libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; then \
		${LN_S} ../src/runtime/libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR} libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../src/runtime/libobjfwrt.dll; then \
		${LN_S} ../src/runtime/libobjfwrt.dll libobjfwrt.dll; \
	fi
	if test -f ../src/runtime/libobjfwrt.dylib; then \
		${LN_S} ../src/runtime/libobjfwrt.dylib \
		    libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib; \
	fi
	if test -f ../src/runtime/${OBJFWRT_AMIGA_LIB}; then \
		${LN_S} ../src/runtime/${OBJFWRT_AMIGA_LIB} \
		    ${OBJFWRT_AMIGA_LIB}; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_FRAMEWORK_PATH=../src:../src/runtime$${DYLD_FRAMEWORK_PATH+:}$$DYLD_FRAMEWORK_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	ASAN_OPTIONS=allocator_may_return_null=1 \
	${WRAPPER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} libobjfw.dll; \
	rm -f libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR}; \
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR} libobjfwrt.dll; \
	rm -f libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib; \
	exit $$EXIT

include ../buildsys.mk

CPPFLAGS += -I../src -I../src/exceptions -I../src/runtime -I..
LIBS := -L../src -lobjfw -L../src/runtime ${RUNTIME_LIBS} ${LIBS}
LD = ${OBJC}
