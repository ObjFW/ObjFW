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
       OFWideCString.m		\
       OFXMLFactory.m

INCLUDES = ${SRCS:.m=.h}

include ../buildsys.mk

CPPFLAGS += -I..
OBJCFLAGS += ${LIB_CFLAGS}
LD = ${OBJC}
LDFLAGS += ${LIB_LDFLAGS}
LIBS += -lobjc
