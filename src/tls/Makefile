include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWTLS_SHARED_LIB}
STATIC_LIB = ${OBJFWTLS_STATIC_LIB}
FRAMEWORK = ${OBJFWTLS_FRAMEWORK}
LIB_MAJOR = ${OBJFWTLS_LIB_MAJOR}
LIB_MINOR = ${OBJFWTLS_LIB_MINOR}
LIB_PATCH = ${OBJFWTLS_LIB_PATCH}

INCLUDES := ObjFWTLS.h
SRCS = ${USE_SRCS_GNUTLS}		\
       ${USE_SRCS_MBEDTLS}		\
       ${USE_SRCS_OPENSSL}		\
       ${USE_SRCS_SECURETRANSPORT}

SRCS_GNUTLS = OFGnuTLSTLSStream.m			\
	      OFGnuTLSX509Certificate.m
SRCS_MBEDTLS = OFMbedTLSTLSStream.m			\
	       OFMbedTLSX509Certificate.m
SRCS_OPENSSL = OFOpenSSLTLSStream.m			\
	       OFOpenSSLX509Certificate.m
SRCS_SECURETRANSPORT = OFSecureTransportKeychain.m			\
		       OFSecureTransportTLSStream.m			\
		       OFSecureTransportX509Certificate.m

includesubdir = ObjFWTLS

include ../../buildsys.mk

install-extra:
	i=ObjFWTLS.oc; \
	${INSTALL_STATUS}; \
	if ${MKDIR_P} ${DESTDIR}${libdir}/objfw-config && \
	    ${INSTALL} -m 644 $$i ${DESTDIR}${libdir}/objfw-config/$$i; then \
		${INSTALL_OK}; \
	else \
		${INSTALL_FAILED}; \
	fi

uninstall-extra:
	i=ObjFWTLS.oc; \
	if test -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
		if rm -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
			${DELETE_OK}; \
		else \
			${DELETE_FAILED}; \
		fi \
	fi
	rmdir ${DESTDIR}${libdir}/objfw-config >/dev/null 2>&1 || true

CPPFLAGS += -I. -I.. -I../.. -I../exceptions -I../runtime ${TLS_CPPFLAGS}
LD = ${OBJC}
FRAMEWORK_LIBS := ${TLS_LIBS} -F.. -framework ObjFW ${LIBS}
LIBS := ${TLS_LIBS} -L.. -lobjfw -L../runtime ${RUNTIME_LIBS} ${LIBS}
