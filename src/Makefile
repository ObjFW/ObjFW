include ../extra.mk

LIB = ${OBJFW_SHARED_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}
STATIC_LIB = ${OBJFW_STATIC_LIB}

SRCS = OFApplication.m		\
       OFArray.m		\
       OFAutoreleasePool.m	\
       OFConstantString.m	\
       OFDataArray.m		\
       OFDictionary.m		\
       OFExceptions.m		\
       OFFile.m			\
       OFHash.m			\
       OFEnumerator.m		\
       OFList.m			\
       OFMD5Hash.m		\
       OFMutableArray.m		\
       OFMutableDictionary.m	\
       OFMutableString.m	\
       OFNumber.m		\
       OFObject.m		\
       ${OFPLUGIN_M}		\
       OFSeekableStream.m	\
       OFSHA1Hash.m		\
       OFStream.m		\
       OFStreamObserver.m	\
       OFStreamSocket.m		\
       OFString.m		\
       OFString+Hashing.m	\
       OFString+URLEncoding.m	\
       OFString+XMLEscaping.m	\
       OFString+XMLUnescaping.m	\
       OFTCPSocket.m		\
       ${OFTHREAD_M}		\
       OFXMLAttribute.m		\
       OFXMLElement.m		\
       OFXMLElementBuilder.m	\
       OFXMLParser.m		\
       unicode.m

INCLUDES := ${SRCS:.m=.h}	\
	    OFBlock.h		\
	    OFCollection.h	\
	    ObjFW.h		\
	    asprintf.h		\
	    ${ATOMIC_H}		\
	    macros.h		\
	    objfw-defs.h	\
	    ${THREADING_H}

SRCS += ${OFBLOCK_M}		\
	${ASPRINTF_M} 		\
	iso_8859_15.m		\
	windows_1252.m		\
	${OBJC_PROPERTIES_M}	\
	${OBJC_SYNC_M}

include ../buildsys.mk

CPPFLAGS += -I..
LD = ${OBJC}
LDFLAGS += ${REEXPORT_LIBOBJC}
