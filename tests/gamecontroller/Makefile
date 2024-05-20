include ../../extra.mk

CLEAN = boot.dol		\
	${PROG_NOINST}.3dsx	\
	${PROG_NOINST}.arm9	\
	${PROG_NOINST}.ndsd	\

PROG_NOINST = gamecontroller_tests${PROG_SUFFIX}
SRCS = GameControllerTests.m

include ../../buildsys.mk

.PHONY: run
run:
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}
	rm -f objfw${OBJFW_LIB_MAJOR}.dll libobjfw.${OBJFW_LIB_MAJOR}.dylib
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR}
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}
	rm -f objfwrt${OBJFWRT_LIB_MAJOR}.dll
	rm -f libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib
	rm -f libobjfwhid.so.${OBJFWHID_LIB_MAJOR}
	rm -f libobjfwhid.so.${OBJFWHID_LIB_MAJOR_MINOR}
	rm -f objfwhid${OBJFWHID_LIB_MAJOR}.dll
	rm -f libobjfwhid.${OBJFWHID_LIB_MAJOR}.dylib
	if test -f ../../src/libobjfw.so; then \
		${LN_S} ../../src/libobjfw.so libobjfw.so.${OBJFW_LIB_MAJOR}; \
		${LN_S} ../../src/libobjfw.so \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	elif test -f ../../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; then \
		${LN_S} ../../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../../src/objfw${OBJFW_LIB_MAJOR}.dll; then \
		${LN_S} ../../src/objfw${OBJFW_LIB_MAJOR}.dll \
		    objfw${OBJFW_LIB_MAJOR}.dll; \
	fi
	if test -f ../../src/libobjfw.dylib; then \
		${LN_S} ../../src/libobjfw.dylib \
		    libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	fi
	if test -f ../../src/runtime/libobjfwrt.so; then \
		${LN_S} ../../src/runtime/libobjfwrt.so \
		    libobjfwrt.so.${OBJFWRT_LIB_MAJOR}; \
		${LN_S} ../../src/runtime/libobjfwrt.so \
		    libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; \
	elif test -f ../../src/runtime/libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR};  then \
		${LN_S} \
		    ../../src/runtime/libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR} \
		    libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../../src/runtime/objfwrt${OBJFWRT_LIB_MAJOR}.dll; then \
		${LN_S} ../../src/runtime/objfwrt${OBJFWRT_LIB_MAJOR}.dll \
		    objfwrt${OBJFWRT_LIB_MAJOR}.dll; \
	fi
	if test -f ../../src/runtime/libobjfwrt.dylib; then \
		${LN_S} ../../src/runtime/libobjfwrt.dylib \
		    libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib; \
	fi
	if test -f ../../src/hid/libobjfwhid.so; then \
		${LN_S} ../../src/hid/libobjfwhid.so \
		    libobjfwhid.so.${OBJFWHID_LIB_MAJOR}; \
		${LN_S} ../../src/hid/libobjfwhid.so \
		    libobjfwhid.so.${OBJFWHID_LIB_MAJOR_MINOR}; \
	elif test -f ../../src/hid/libobjfwhid.so.${OBJFWHID_LIB_MAJOR_MINOR}; \
	then \
		${LN_S} ../../src/hid/libobjfwhid.so.${OBJFWHIID_LIB_MAJOR_MINOR} \
		    libobjfwhid.so.${OBJFWHID_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../../src/hid/objfwhid${OBJFWHID_LIB_MAJOR}.dll; then \
		${LN_S} ../../src/hid/objfwhid${OBJFWHID_LIB_MAJOR}.dll \
		    objfwhid${OBJFWHID_LIB_MAJOR}.dll; \
	fi
	if test -f ../../src/hid/libobjfwhid.dylib; then \
		${LN_S} ../../src/hid/libobjfwhid.dylib \
		    libobjfwhid.${OBJFWHID_LIB_MAJOR}.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_FRAMEWORK_PATH=../../src:../../src/runtime:../../src/hid$${DYLD_FRAMEWORK_PATH+:}$$DYLD_FRAMEWORK_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	ASAN_OPTIONS=allocator_may_return_null=1 \
	${WRAPPER} ./${PROG_NOINST} ${TESTCASES}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	rm -f objfw${OBJFW_LIB_MAJOR}.dll; \
	rm -f libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR}; \
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; \
	rm -f objfwrt${OBJFWRT_LIB_MAJOR}.dll; \
	rm -f libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib; \
	rm -f libobjfwhid.so.${OBJFWHID_LIB_MAJOR}; \
	rm -f libobjfwhid.so.${OBJFWHID_LIB_MAJOR_MINOR}; \
	rm -f objfwhid${OBJFWHID_LIB_MAJOR}.dll; \
	rm -f libobjfwhid.${OBJFWHID_LIB_MAJOR}.dylib; \
	exit $$EXIT

boot.dol: ${PROG_NOINST}
	elf2dol ${PROG_NOINST} $@

${PROG_NOINST}: ${LIBOBJFW_DEP_LVL2} ${LIBOBJFWRT_DEP_LVL2} \
		${LIBOBJFWHID_DEP_LVL2}

${PROG_NOINST}.3dsx: ${PROG_NOINST}
	3dsxtool $< $@

${PROG_NOINST}.arm9: ${PROG_NOINST}
	arm-none-eabi-objcopy -O binary $< $@

${PROG_NOINST}.nds: ${PROG_NOINST}.arm9
	ndstool -c $@ -9 ${PROG_NOINST}

CPPFLAGS += -I../../src			\
	    -I../../src/exceptions	\
	    -I../../src/hid		\
	    -I../../src/runtime		\
	    -I../..			\
	    -DOBJFWHID_LOCAL_INCLUDES
LIBS := -L../../src/hid -lobjfwhid ${HID_LIBS}	\
	-L../../src -lobjfw			\
	-L../../src/runtime ${RUNTIME_LIBS}	\
	${LIBS}
LD = ${OBJC}
