include ../extra.mk

SUBDIRS = exceptions

SHARED_LIB = ${OBJFW_SHARED_LIB}
STATIC_LIB = ${OBJFW_STATIC_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFApplication.m			\
       OFArray.m			\
       OFAutoreleasePool.m		\
       OFBlock.m			\
       OFConstantString.m		\
       OFCountedSet.m			\
       OFDataArray.m			\
       OFDataArray+Hashing.m		\
       OFDate.m				\
       OFDictionary.m			\
       OFDoubleMatrix.m			\
       OFDoubleVector.m			\
       OFEnumerator.m			\
       OFFile.m				\
       OFFloatMatrix.m			\
       OFFloatVector.m			\
       OFHash.m				\
       OFHTTPRequest.m			\
       OFIntrospection.m		\
       OFList.m				\
       OFMD5Hash.m			\
       OFMutableArray.m			\
       OFMutableDictionary.m		\
       OFMutableSet.m			\
       OFMutableString.m		\
       OFNull.m				\
       OFNumber.m			\
       OFObject.m			\
       OFObject+Serialization.m		\
       ${OFPLUGIN_M}			\
       OFSeekableStream.m		\
       OFSet.m				\
       OFSHA1Hash.m			\
       OFStream.m			\
       OFStreamObserver.m		\
       OFStreamSocket.m			\
       OFString.m			\
       OFString+Hashing.m		\
       OFString+Serialization.m		\
       OFString+URLEncoding.m		\
       OFString+XMLEscaping.m		\
       OFString+XMLUnescaping.m		\
       OFTCPSocket.m			\
       ${OFTHREAD_M}			\
       OFURL.m				\
       OFXMLAttribute.m			\
       OFXMLCDATA.m			\
       OFXMLCharacters.m		\
       OFXMLComment.m			\
       OFXMLElement.m			\
       OFXMLElement+Serialization.m	\
       OFXMLElementBuilder.m		\
       OFXMLNode.m			\
       OFXMLParser.m			\
       base64.m				\
       of_asprintf.m			\
       unicode.m

INCLUDES := ${SRCS:.m=.h}	\
	    OFCollection.h	\
	    OFSerialization.h	\
	    ObjFW.h		\
	    asprintf.h		\
	    ${ATOMIC_H}		\
	    macros.h		\
	    objfw-defs.h	\
	    ${THREADING_H}

SRCS += OFArray_adjacent.m		\
	OFArray_adjacentSubarray.m	\
	OFArray_subarray.m		\
	OFCountedSet_hashtable.m	\
	OFDictionary_hashtable.m	\
	OFMutableArray_adjacent.m	\
	OFMutableDictionary_hashtable.m	\
	OFMutableSet_hashtable.m	\
	OFSet_hashtable.m		\
	${OFSTREAMOBSERVER_KQUEUE_M}	\
	${OFSTREAMOBSERVER_POLL_M}	\
	${OFSTREAMOBSERVER_SELECT_M}	\
	OFTCPSocket+SOCKS5.m		\
	${ASPRINTF_M}			\
	${FOUNDATION_COMPAT_M}		\
	iso_8859_15.m			\
	windows_1252.m			\
	${OBJC_PROPERTIES_M}		\
	${OBJC_SYNC_M}

include ../buildsys.mk

CPPFLAGS += -I. -I.. -Iexceptions
LD = ${OBJC}
LDFLAGS += ${REEXPORT_LIBOBJC} ${MACH_ALIAS_LIST}

LIB_OBJS += ${EXCEPTIONS_EXCEPTIONS_LIB_A}
OBJS += ${EXCEPTIONS_EXCEPTIONS_A}
