include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWBRIDGE_SHARED_LIB}
STATIC_LIB = ${OBJFWBRIDGE_STATIC_LIB}
FRAMEWORK = ${OBJFWBRIDGE_FRAMEWORK}
LIB_MAJOR = ${OBJFWBRIDGE_LIB_MAJOR}
LIB_MINOR = ${OBJFWBRIDGE_LIB_MINOR}
LIB_PATCH = ${OBJFWBRIDGE_LIB_PATCH}

SRCS = NSArray+OFObject.m	\
       NSData+OFObject.m	\
       NSDate+OFObject.m	\
       NSDictionary+OFObject.m	\
       NSEnumerator+OFObject.m	\
       NSNumber+OFObject.m	\
       NSSet+OFObject.m		\
       NSString+OFObject.m	\
       OFArray+NSObject.m	\
       OFData+NSObject.m	\
       OFDate+NSObject.m	\
       OFDictionary+NSObject.m	\
       OFEnumerator+NSObject.m	\
       OFException+OFSwift.m	\
       OFNumber+NSObject.m	\
       OFSet+NSObject.m		\
       OFString+NSObject.m

INCLUDES := ${SRCS:.m=.h}	\
	    OFNSToOFBridging.h	\
	    OFOFToNSBridging.h	\
	    ObjFWBridge.h

SRCS += NSOFArray.m		\
	NSOFData.m		\
	NSOFDictionary.m	\
	NSOFEnumerator.m	\
	NSOFSet.m		\
	OFNSArray.m		\
	OFNSData.m		\
	OFNSDictionary.m	\
	OFNSEnumerator.m	\
	OFNSSet.m		\
	${USE_SRCS_SOCKETS}
SRCS_SOCKETS = OFCFRunLoopKernelEventObserver.m

includesubdir = ObjFWBridge

include ../../buildsys.mk

install-extra:
	i=ObjFWBridge.oc; \
	${INSTALL_STATUS}; \
	if ${MKDIR_P} ${DESTDIR}${libdir}/objfw-config && \
	    ${INSTALL} -m 644 $$i ${DESTDIR}${libdir}/objfw-config/$$i; then \
		${INSTALL_OK}; \
	else \
		${INSTALL_FAILED}; \
	fi

uninstall-extra:
	i=ObjFWBridge.oc; \
	if test -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
		if rm -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
			${DELETE_OK}; \
		else \
			${DELETE_FAILED}; \
		fi \
	fi
	rmdir ${DESTDIR}${libdir}/objfw-config >/dev/null 2>&1 || true

CPPFLAGS += -I. -I.. -I../.. -I../exceptions -DOBJFWBRIDGE_LOCAL_INCLUDES
LD = ${OBJC}
FRAMEWORK_LIBS := -F..				\
		  -F../runtime			\
		  -framework Foundation		\
		  -framework ObjFW		\
		  ${RUNTIME_FRAMEWORK_LIBS}	\
		  ${LIBS}
LIBS := -L.. -L../runtime -framework Foundation -lobjfw ${RUNTIME_LIBS} ${LIBS}
