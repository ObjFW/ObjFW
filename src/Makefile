include ../extra.mk

LIB = ${LIB_PREFIX}objfw${LIB_SUFFIX}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

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
	    ObjFW.h		\
	    asprintf.h		\
	    ${ATOMIC_H}		\
	    macros.h		\
	    objfw-defs.h	\
	    ${THREADING_H}

SRCS += ${ASPRINTF_M} 		\
	iso_8859_15.m		\
	windows_1252.m		\
	${OBJC_PROPERTIES_M}	\
	${OBJC_SYNC_M}

include ../buildsys.mk

CPPFLAGS += -I.. ${LIB_CPPFLAGS}
OBJCFLAGS += ${LIB_CFLAGS}
LD = ${OBJC}
