include ../extra.mk

LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFArray.m		\
       OFAutoreleasePool.m	\
       OFConstString.m		\
       OFDictionary.m		\
       OFExceptions.m		\
       OFFile.m			\
       OFHashes.m		\
       OFIterator.m		\
       OFList.m			\
       OFNumber.m		\
       OFObject.m		\
       ${OFPLUGIN_M}		\
       OFString.m		\
       OFTCPSocket.m		\
       OFXMLFactory.m		\
       ${ASPRINTF_C}

INCLUDESTMP = ${SRCS:.c=.h}
INCLUDES = ${INCLUDESTMP:.m=.h}	\
	   OFMacros.h		\
	   OFStream.h

include ../buildsys.mk

CPPFLAGS += -I..
CFLAGS += ${LIB_CFLAGS}
OBJCFLAGS += ${LIB_CFLAGS}
LD = ${OBJC}
LDFLAGS += ${LIB_LDFLAGS}
