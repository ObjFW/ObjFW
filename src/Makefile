include ../extra.mk

LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 0
LIB_MINOR = 1

SRCS = OFArray.m		\
       OFAutoreleasePool.m	\
       OFConstString.m		\
       OFDataArray.m		\
       OFDictionary.m		\
       OFExceptions.m		\
       OFFile.m			\
       OFHashes.m		\
       OFIterator.m		\
       OFList.m			\
       OFMutableArray.m		\
       OFMutableDictionary.m	\
       OFMutableString.m	\
       OFNumber.m		\
       OFObject.m		\
       ${OFPLUGIN_M}		\
       OFSocket.m		\
       OFStream.m		\
       OFString.m		\
       OFTCPSocket.m		\
       OFThread.m		\
       OFURLEncoding.m		\
       OFXMLFactory.m		\
       ${ASPRINTF_C}

INCLUDESTMP = ${SRCS:.c=.h}
INCLUDES = ${INCLUDESTMP:.m=.h}	\
	   OFMacros.h

include ../buildsys.mk

CPPFLAGS += -I..
CFLAGS += ${LIB_CFLAGS}
OBJCFLAGS += ${LIB_CFLAGS}
LD = ${OBJC}
LDFLAGS += ${LIB_LDFLAGS}
