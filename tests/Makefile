include ../extra.mk

SUBDIRS = ${TESTPLUGIN}

PROG_NOINST = tests${PROG_SUFFIX}
SRCS = OFArrayTests.m		\
       OFDataArrayTests.m	\
       OFDictionaryTests.m	\
       OFFileTests.m		\
       OFListTests.m		\
       OFMD5HashTests.m		\
       OFNumberTests.m		\
       OFObjectTests.m		\
       ${OFPLUGINTESTS_M}	\
       OFSHA1HashTests.m	\
       OFStreamTests.m		\
       OFStringTests.m		\
       OFTCPSocketTests.m	\
       ${OFTHREADTESTS_M}	\
       OFXMLElementTests.m	\
       OFXMLParserTests.m	\
       ${PROPERTIESTESTS_M}	\
       TestsAppDelegate.m

IPHONE_USER = mobile
IPHONE_TMP = /tmp/objfw-test

.PHONY: run run-tests run-on-iphone
run: all
	if [ -z "${DONT_RUN_TESTS}" ]; then ${MAKE} ${MFLAGS} run-tests; fi

run-tests:
	rm -f libobjfw.so.1 libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}
	rm -f libobjfw.dll libobjfw.dylib
	if test -f ../src/libobjfw.so; then \
		ln -s ../src/libobjfw.so libobjfw.so.${OBJFW_LIB_MAJOR}; \
		ln -s ../src/libobjfw.so libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	elif test -f ../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; then \
		ln -s ../src/libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} \
			libobjfw.so.${OBJFW_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../src/libobjfw.dll; then \
		ln ../src/libobjfw.dll libobjfw.dll; \
	fi
	if test -f ../src/libobjfw.dylib; then \
		ln -s ../src/libobjfw.dylib libobjfw.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR}; \
	rm -f libobjfw.so.${OBJFW_LIB_MAJOR_MINOR} libobjfw.dll \
	rm -f libobjfw.dylib; \
	exit $$EXIT

run-on-iphone: all
	if [ -z "${IPHONE_HOST}" ]; then \
		echo "Please set IPHONE_HOST to the hostname of your iPhone!"; \
		exit 1; \
	fi
	echo "Uploading files to iPhone ${IPHONE_HOST} at ${IPHONE_TMP}..."
	ssh ${IPHONE_USER}@${IPHONE_HOST} \
		'rm -fr ${IPHONE_TMP} && mkdir -p ${IPHONE_TMP}/plugin'
	scp -q ../src/libobjfw.dylib tests testfile.bin testfile.txt \
		${IPHONE_USER}@${IPHONE_HOST}:${IPHONE_TMP}/
	scp -q plugin/TestPlugin.impl \
		${IPHONE_USER}@${IPHONE_HOST}:${IPHONE_TMP}/plugin/
	echo "Signing and running tests binary on iPhone ${IPHONE_HOST}..."
	ssh ${IPHONE_USER}@${IPHONE_HOST} \
		'cd ${IPHONE_TMP} && ldid -S tests && ./tests'

include ../buildsys.mk

CPPFLAGS += -I../src -I.. -DSTDOUT
LIBS := -L../src -lobjfw ${LIBS}
LD = ${OBJC}
