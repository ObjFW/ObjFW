include ../../extra.mk

DISTCLEAN = Info.plist

STATIC_LIB = libobjfwtest.a

SRCS = OTAssert.m		\
       OTOrderedDictionary.m	\
       OTTestCase.m
INCLUDES := ${SRCS:.m=.h}	\
	    ObjFWTest.h
SRCS += OTAppDelegate.m			\
	OTAssertionFailedException.m	\
	OTTestSkippedException.m

includesubdir = ObjFWTest

include ../../buildsys.mk

CPPFLAGS += -I. 			\
	    -I..			\
	    -I../..			\
	    -I../exceptions		\
	    -I../runtime		\
	    -DOBJFWTEST_LOCAL_INCLUDES
LD = ${OBJC}
FRAMEWORK_LIBS := -F..				\
		  -framework ObjFW		\
		  -F../runtime			\
		  ${RUNTIME_FRAMEWORK_LIBS}	\
		  ${LIBS}
LIBS := -L.. -lobjfw -L../runtime ${RUNTIME_LIBS} ${LIBS}

install-extra:
	i=ObjFWTest.oc; \
	${INSTALL_STATUS}; \
	if ${MKDIR_P} ${libdir}/objfw-config && ${INSTALL} -m 644 $$i ${libdir}/objfw-config/$$i; then \
		${INSTALL_OK}; \
	else \
		${INSTALL_FAILED}; \
	fi

uninstall-extra:
	i=ObjFWTest.oc; \
	if test -f ${libdir}/objfw-config/$$i; then \
		if rm -f ${libdir}/objfw-config/$$i; then \
			${DELETE_OK}; \
		else \
			${DELETE_FAILED}; \
		fi \
	fi; \
	rmdir ${libdir}/objfw-config >/dev/null 2>&1 || true
