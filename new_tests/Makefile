include ../extra.mk

SUBDIRS = ${TESTPLUGIN} ${SUBPROCESS}

CLEAN = EBOOT.PBP		\
	boot.dol		\
	${PROG_NOINST}.arm9	\
	${PROG_NOINST}.nds	\
	${PROG_NOINST}.nro	\
	${PROG_NOINST}.rpx	\
	testfile_bin.m		\
	testfile_ini.m

PROG_NOINST = tests${PROG_SUFFIX}
SRCS = OFASN1DERParsingTests.m		\
       OFArrayTests.m			\
       OFCharacterSetTests.m		\
       OFColorTests.m			\
       OFConcreteArrayTests.m		\
       OFConcreteMutableArrayTests.m	\
       OFCryptographicHashTests.m	\
       OFDateTests.m			\
       OFHMACTests.m			\
       OFINIFileTests.m			\
       OFIRITests.m			\
       OFInvocationTests.m		\
       OFJSONTests.m			\
       OFMatrix4x4Tests.m		\
       OFMethodSignatureTests.m		\
       OFMutableArrayTests.m		\
       OFNumberTests.m			\
       OFPBKDF2Tests.m			\
       OFPropertyListTests.m		\
       OFScryptTests.m			\
       ${USE_SRCS_PLUGINS}		\
       ${USE_SRCS_SOCKETS}		\
       ${USE_SRCS_SUBPROCESSES}		\
       ${USE_SRCS_THREADS}		\
       testfile_bin.m			\
       testfile_ini.m
SRCS_PLUGINS = OFPluginTests.m
SRCS_SOCKETS = OFSocketTests.m
SRCS_SUBPROCESSES = OFSubprocessTests.m
SRCS_THREADS = OFThreadTests.m

include ../buildsys.mk

testfile_bin.m: testfile.bin
	${SHELL} ../utils/objfw-embed testfile.bin testfile.bin $@
testfile_ini.m: testfile.ini
	${SHELL} ../utils/objfw-embed testfile.ini testfile.ini $@

.PHONY: run run-on-ios run-on-android
run:
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}
	rm -f objfw${OBJFW_LIB_MAJOR}.dll libobjfw.${OBJFW_LIB_MAJOR}.dylib
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR}
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}
	rm -f objfwrt${OBJFWRT_LIB_MAJOR}.dll
	rm -f libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib
	if test -f ../src/libobjfw.so; then \
		${LN_S} ../src/libobjfw.so libobjfw.so.${OBJFW_LIB_MAJOR}; \
		${LN_S} ../src/libobjfw.so \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	elif test -f ../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; then \
		${LN_S} ../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} \
		    libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../src/objfw${OBJFW_LIB_MAJOR}.dll; then \
		${LN_S} ../src/objfw${OBJFW_LIB_MAJOR}.dll \
			objfw${OBJFW_LIB_MAJOR}.dll; \
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
	if test -f ../src/runtime/objfwrt${OBJFWRT_LIB_MAJOR}.dll; then \
		${LN_S} ../src/runtime/objfwrt${OBJFWRT_LIB_MAJOR}.dll \
			objfwrt${OBJFWRT_LIB_MAJOR}.dll; \
	fi
	if test -f ../src/runtime/libobjfwrt.dylib; then \
		${LN_S} ../src/runtime/libobjfwrt.dylib \
		    libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_FRAMEWORK_PATH=../src:../src/runtime$${DYLD_FRAMEWORK_PATH+:}$$DYLD_FRAMEWORK_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	ASAN_OPTIONS=allocator_may_return_null=1 \
	${WRAPPER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	rm -f objfw${OBJFW_LIB_MAJOR}.dll; \
	rm -f libobjfw.${OBJFW_LIB_MAJOR}.dylib; \
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR}; \
	rm -f libobjfwrt.so.${OBJFWRT_LIB_MAJOR_MINOR}; \
	rm -f objfwrt${OBJFWRT_LIB_MAJOR}.dll; \
	rm -f libobjfwrt.${OBJFWRT_LIB_MAJOR}.dylib; \
	exit $$EXIT

run-on-android: all
	echo "Uploading files to Android device..."
	if test -f ../src/libobjfw.so; then \
		adb push ../src/libobjfw.so \
		    /data/local/tmp/objfw/libobjfw.so.${OBJFW_LIB_MAJOR}; \
	fi
	if test -f ../src/runtime/libobjfwrt.so; then \
		adb push ../src/runtime/libobjfwrt.so \
		    /data/local/tmp/objfw/libobjfwrt.so.${OBJFWRT_LIB_MAJOR}; \
	fi
	adb push tests /data/local/tmp/objfw/tests
	adb push testfile.txt /data/local/tmp/objfw/testfile.txt
	if test -f plugin/TestPlugin.so; then \
		adb push plugin/TestPlugin.so \
		    /data/local/tmp/objfw/plugin/TestPlugin.so; \
	fi
	echo "Running tests binary on Android device..."
	adb shell 'cd /data/local/tmp/objfw && LD_LIBRARY_PATH=. exec ${WRAPPER} ./tests'

EBOOT.PBP: ${PROG_NOINST}
	psp-fixup-imports ${PROG_NOINST}
	mksfo "ObjFW Tests" PARAM.SFO
	psp-strip ${PROG_NOINST}
	pack-pbp $@ PARAM.SFO NULL NULL NULL NULL NULL ${PROG_NOINST} NULL

boot.dol: ${PROG_NOINST}
	elf2dol ${PROG_NOINST} $@

${PROG_NOINST}: ${LIBOBJFW_DEP} ${LIBOBJFWRT_DEP} ../src/test/libobjfwtest.a

${PROG_NOINST}.3dsx: ${PROG_NOINST}
	3dsxtool $< $@

${PROG_NOINST}.arm9: ${PROG_NOINST}
	arm-none-eabi-objcopy -O binary $< $@

${PROG_NOINST}.nds: ${PROG_NOINST}.arm9 testfile.txt
	rm -fr nds-data
	mkdir -p nds-data
	cp testfile.txt nds-data
	ndstool -c $@ -9 ${PROG_NOINST} -d nds-data
	rm -fr nds-data

${PROG_NOINST}.nro: ${PROG_NOINST} testfile.txt
	rm -fr romfs
	mkdir -p romfs
	cp testfile.txt romfs
	nacptool --create "ObjFW tests" "Jonathan Schleifer" \
		"${PACKAGE_VERSION}" tests.nacp
	elf2nro ${PROG_NOINST} $@ --nacp=tests.nacp --romfsdir=romfs
	rm -fr romfs tests.nacp

${PROG_NOINST}.rpx: ${PROG_NOINST}
	elf2rpl $< $@

CPPFLAGS += -I../src				\
	    -I../src/exceptions			\
	    -I../src/runtime			\
	    -I../src/test			\
	    -I..				\
	    -DOBJFWTEST_LOCAL_INCLUDES		\
	    -DPROG_SUFFIX=\"${PROG_SUFFIX}\"
# Repetition is required for Wii U, as otherwise it cannot find main. Just
# moving -lobjfwtest later doesn't work either, as then the linker cannot find
# ObjFW symbols. So the only solution is to list everything twice.
LIBS := -L../src/test	\
	-lobjfwtest	\
	${TESTS_LIBS}	\
	${LIBS}		\
	-lobjfwtest	\
	${TESTS_LIBS}	\
	${LIBS}
LDFLAGS += ${MAP_LDFLAGS}
LD = ${OBJC}
