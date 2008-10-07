LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFConstCString.m		\
       OFCString.m		\
       OFConstWideCString.m	\
       OFExceptions.m		\
       OFFile.m			\
       OFList.m			\
       OFListObject.m		\
       OFObject.m		\
       OFString.m		\
       OFWideCString.m

INCLUDES = OFConstString.h	\
	   OFCString.h		\
	   OFConstWideString.h	\
	   OFExceptions.h	\
	   OFFile.h		\
	   OFList.h		\
	   OFListObject.h	\
	   OFObject.h		\
	   OFString.h		\
	   OFWideString.h

include ../buildsys.mk

OBJCFLAGS += ${LIB_CFLAGS}
LD = ${OBJC}
LDFLAGS += ${LIB_LDFLAGS}
LIBS += -lobjc
