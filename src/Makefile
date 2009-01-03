include ../extra.mk

LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFArray.m		\
       OFExceptions.m		\
       OFHashes.m		\
       OFFile.m			\
       OFList.m			\
       OFListObject.m		\
       OFNumber.m		\
       OFObject.m		\
       OFString.m		\
       OFTCPSocket.m		\
       OFXMLFactory.m		\
       ${ASPRINTF}

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
