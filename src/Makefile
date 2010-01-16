include ../extra.mk

LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = 1
LIB_MINOR = 0

SRCS = OFArray.m		\
       OFAutoreleasePool.m	\
       OFConstString.m		\
       OFDataArray.m		\
       OFDictionary.m		\
       OFExceptions.m		\
       OFFile.m			\
       OFHashes.m		\
       OFEnumerator.m		\
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
       ${OFTHREAD_M}		\
       OFURLEncoding.m		\
       OFXMLElement.m		\
       OFXMLParser.m		\
       unicode.m

INCLUDES := ${SRCS:.m=.h}	\
	    OFFastEnumeration.h	\
	    OFMacros.h		\
	    ObjFW.h		\
	    asprintf.h		\
	    objfw-defs.h	\
	    ${THREADING_H}

SRCS += ${AS_PRINTF_M} 		\
	iso_8859_15.m		\
	windows_1252.m		\
	${OBJC_PROPERTIES_M}	\
	${OBJC_SYNC_M}

include ../buildsys.mk

CPPFLAGS += -I..
OBJCFLAGS += ${LIB_CFLAGS}
LD = ${OBJC}
