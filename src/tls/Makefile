include ../../extra.mk

SUBDIRS = ${LINKLIB}
DISTCLEAN = Info.plist	\
	    ObjFWTLS.oc

SHARED_LIB = ${OBJFWTLS_SHARED_LIB}
STATIC_LIB = ${OBJFWTLS_STATIC_LIB}
FRAMEWORK = ${OBJFWTLS_FRAMEWORK}
AMIGA_LIB = ${OBJFWTLS_AMIGA_LIB}
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

AMIGA_LIB_OBJS_START = amiga-library.amigalib.o
AMIGA_LIB_OBJS_EXTRA = amiga-library-glue.amigalib.o
AMIGA_LIB_OBJS_END = amiga-library-end.amigalib.o

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

CPPFLAGS += -I.							\
	    -I..						\
	    -I../..						\
	    -I../exceptions					\
	    -I../runtime					\
	    -I../bridge						\
	    -DOBJFWBRIDGE_LOCAL_INCLUDES			\
	    -DOBJFWTLS_AMIGA_LIB=\"${OBJFWTLS_AMIGA_LIB}\"	\
	    -DOBJFWTLS_LIB_MAJOR=${OBJFWTLS_LIB_MAJOR}		\
	    -DOBJFWTLS_LIB_MINOR=${OBJFWTLS_LIB_MINOR}		\
	    -DOBJFWTLS_LIB_PATCH=${OBJFWTLS_LIB_PATCH}		\
	    -DBUILD_DATE=\"$$(date +%d.%m.%y)\"			\
	    ${TLS_CPPFLAGS}
AMIGA_LIB_CFLAGS += -DOF_COMPILING_AMIGA_LIBRARY
LD = ${OBJC}
FRAMEWORK_LIBS := -F..				\
		  -F../runtime			\
		  -F../bridge			\
		  ${TLS_FRAMEWORK_LIBS}		\
		  -framework ObjFW		\
		  ${RUNTIME_FRAMEWORK_LIBS}	\
		  ${LIBS}
AMIGA_LIB_LIBS := -L../runtime/linklib		\
		  -L../linklib 			\
		  -lssl_sharedext		\
		  -lcrypto_sharedext		\
		  -lobjfw.library.amigalib	\
		  -lobjfwrt.library.amigalib	\
		  ${LIBS}			\
		  ${AMIGA_LIB_LIBS}
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
