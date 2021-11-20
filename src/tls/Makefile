include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWTLS_SHARED_LIB}
STATIC_LIB = ${OBJFWTLS_STATIC_LIB}
FRAMEWORK = ${OBJFWTLS_FRAMEWORK}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

INCLUDES := ObjFWTLS.h
SRCS = ${OF_SECURE_TRANSPORT_TLS_STREAM_M}

includesubdir = ObjFWTLS

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../exceptions
LD = ${OBJC}
FRAMEWORK_LIBS := ${TLS_LIBS} -F.. -framework ObjFW ${LIBS}
LIBS := ${TLS_LIBS} -L.. -lobjfw ${LIBS}
