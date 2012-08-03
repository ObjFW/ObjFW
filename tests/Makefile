include ../extra.mk

SUBDIRS = ${TESTPLUGIN}

PROG_NOINST = tests${PROG_SUFFIX}
SRCS = ForwardingTests.m		\
       OFArrayTests.m			\
       ${OFBLOCKTESTS_M}		\
       OFDataArrayTests.m		\
       OFDateTests.m			\
       OFDictionaryTests.m		\
       ${OFHTTPREQUESTTESTS_M}		\
       OFJSONTests.m			\
       OFListTests.m			\
       OFMD5HashTests.m			\
       OFNumberTests.m			\
       OFObjectTests.m			\
       ${OFPLUGINTESTS_M}		\
       OFSerializationTests.m		\
       OFSet.m				\
       OFSHA1HashTests.m		\
       OFStreamTests.m			\
       OFStringTests.m			\
       OFTCPSocketTests.m		\
       ${OFTHREADTESTS_M}		\
       OFURLTests.m			\
       OFXMLElementBuilderTests.m	\
       OFXMLNodeTests.m			\
       OFXMLParserTests.m		\
       ${PROPERTIESTESTS_M}		\
       TestsAppDelegate.m

IOS_USER ?= mobile
IOS_TMP ?= /tmp/objfw-test

.PHONY: run run-tests run-on-ios
run: all
	if [ -z "${DONT_RUN_TESTS}" ]; then ${MAKE} ${MFLAGS} run-tests; fi

run-tests:
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
		${LN_S} ../src/libobjfw.dylib libobjfw.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} libobjfw.dll \
	rm -f libobjfw.dylib; \
	exit $$EXIT

sign-for-ios: all
	codesign -s "iPhone Developer" -f \
		../src/libobjfw.dylib tests plugin/TestPlugin.bundle

run-on-ios: all sign-for-ios
	if [ -z "${IOS_HOST}" ]; then \
		echo "Please set IOS_HOST to the hostname of your iOS host!"; \
		exit 1; \
	fi
	echo "Uploading files to iOS device ${IOS_HOST} at ${IOS_TMP}..."
	ssh ${IOS_USER}@${IOS_HOST} \
		'rm -fr ${IOS_TMP} && mkdir -p ${IOS_TMP}/plugin'
	scp -q ../src/libobjfw.dylib tests testfile.bin testfile.txt \
		serialization.xml ${IOS_USER}@${IOS_HOST}:${IOS_TMP}/
	scp -q plugin/TestPlugin.bundle \
		${IOS_USER}@${IOS_HOST}:${IOS_TMP}/plugin/
	echo "Running tests binary on iOS device ${IOS_HOST}..."
	ssh ${IOS_USER}@${IOS_HOST} \
		'cd ${IOS_TMP} && ${TEST_LAUNCHER} ./tests'

EBOOT.PBP: ${PROG_NOINST}
	psp-fixup-imports ${PROG_NOINST}
	mksfo "ObjFW Tests" PARAM.SFO
	psp-strip ${PROG_NOINST}
	pack-pbp $@ PARAM.SFO NULL NULL NULL NULL NULL ${PROG_NOINST} NULL

include ../buildsys.mk

CPPFLAGS += -I../src -I../src/exceptions -I../src/runtime -I.. -DSTDOUT
LIBS := -L../src -lobjfw ${LIBS}
LD = ${OBJC}
