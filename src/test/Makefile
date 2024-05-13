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

install-extra:
	i=ObjFWTest.oc; \
	${INSTALL_STATUS}; \
	if ${MKDIR_P} ${DESTDIR}${libdir}/objfw-config && \
	    ${INSTALL} -m 644 $$i ${DESTDIR}${libdir}/objfw-config/$$i; then \
		${INSTALL_OK}; \
	else \
		${INSTALL_FAILED}; \
	fi

uninstall-extra:
	i=ObjFWTest.oc; \
	if test -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
		if rm -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
			${DELETE_OK}; \
		else \
			${DELETE_FAILED}; \
		fi \
	fi
	rmdir ${DESTDIR}${libdir}/objfw-config >/dev/null 2>&1 || true

CPPFLAGS += -I. 			\
	    -I..			\
	    -I../..			\
	    -I../exceptions		\
	    -I../runtime		\
	    -DOBJFWTEST_LOCAL_INCLUDES
LD = ${OBJC}
