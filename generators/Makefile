include ../extra.mk

PROG_NOINST = gen_tables${PROG_SUFFIX}
SRCS = TableGenerator.m

.PHONY: run
run: all
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}
	rm -f libobjfw.dll libobjfw.dylib
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
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} libobjfw.dll \
	rm -f libobjfw.dylib; \
	exit $$EXIT

include ../buildsys.mk

CPPFLAGS += -I../src -I../src/runtime -I..
LIBS := -L../src -lobjfw ${LIBS}
LD = ${OBJC}
