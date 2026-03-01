include ../../extra.mk

DISTCLEAN = Info.plist	\
	    ObjFWTLS.oc

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
       ${USE_SRCS_WINDOWS}
SRCS_GNUTLS = OFGnuTLSTLSStream.m			\
	      OFGnuTLSX509Certificate.m
SRCS_MBEDTLS = OFMbedTLSTLSStream.m			\
	       OFMbedTLSX509Certificate.m
SRCS_OPENSSL = OFOpenSSLTLSStream.m			\
	       OFOpenSSLX509Certificate.m
SRCS_WINDOWS = versioninfo.rc

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

# OpenSSL headers shadow functions with variables and make Apple GCC 4.0.1
# complain.
OBJCFLAGS_OFOpenSSLTLSStream.m += -Wno-shadow
OBJCFLAGS_OFOpenSSLX509Certificate.m += -Wno-shadow

CPPFLAGS += -I.					\
	    -I..				\
	    -I../..				\
	    -I../exceptions			\
	    -I../runtime			\
	    -I../bridge				\
	    -DOBJFWBRIDGE_LOCAL_INCLUDES	\
	    ${TLS_CPPFLAGS}
LD = ${OBJC}
FRAMEWORK_LIBS := -F..				\
		  -F../runtime			\
		  -F../bridge			\
		  ${TLS_FRAMEWORK_LIBS}		\
		  -framework ObjFW		\
		  ${RUNTIME_FRAMEWORK_LIBS}	\
		  ${LIBS}
LIBS := -L..		\
	-L../runtime	\
	-L../bridge	\
	${TLS_LIBS}	\
	-lobjfw		\
	${RUNTIME_LIBS}	\
	${LIBS}
RCFLAGS = --use-temp-file						     \
	  -DOBJFWTLS_LIB_MAJOR=${OBJFWTLS_LIB_MAJOR}			     \
	  -DOBJFWTLS_LIB_MINOR=${OBJFWTLS_LIB_MINOR}			     \
	  -DOBJFWTLS_LIB_VER=\"${OBJFWTLS_LIB_MAJOR}.${OBJFWTLS_LIB_MINOR}\" \
	  -DOBJFWTLS_SHARED_LIB=\"${OBJFWTLS_SHARED_LIB}\"
