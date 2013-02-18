include ../extra.mk

SUBDIRS = exceptions ${RUNTIME} ${BRIDGE}

SHARED_LIB = ${OBJFW_SHARED_LIB}
STATIC_LIB = ${OBJFW_STATIC_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFApplication.m			\
       OFArray.m			\
       OFArray_subarray.m		\
       OFAutoreleasePool.m		\
       OFBlock.m			\
       OFConstantString.m		\
       OFCountedSet.m			\
       OFDataArray.m			\
       OFDataArray+Hashing.m		\
       OFDate.m				\
       OFDictionary.m			\
       OFEnumerator.m			\
       OFFile.m				\
       OFHTTPClient.m			\
       OFHTTPRequest.m			\
       OFHTTPRequestReply.m		\
       OFHTTPServer.m			\
       OFIntrospection.m		\
       OFList.m				\
       OFMapTable.m			\
       OFMD5Hash.m			\
       OFMutableArray.m			\
       OFMutableDictionary.m		\
       OFMutableSet.m			\
       OFMutableString.m		\
       OFNull.m				\
       OFNumber.m			\
       OFObject.m			\
       OFObject+Serialization.m		\
       OFProcess.m			\
       OFRunLoop.m			\
       OFSeekableStream.m		\
       OFSet.m				\
       OFSHA1Hash.m			\
       OFSortedList.m			\
       OFStream.m			\
       OFStreamObserver.m		\
       OFStreamSocket.m			\
       OFString.m			\
       OFString+Hashing.m		\
       OFString+JSONValue.m		\
       OFString+Serialization.m		\
       OFString+URLEncoding.m		\
       OFString+XMLEscaping.m		\
       OFString+XMLUnescaping.m		\
       OFSystemInfo.m			\
       OFTCPSocket.m			\
       OFTimer.m			\
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
       OFXMLProcessingInstructions.m	\
       base64.m				\
       of_asprintf.m			\
       of_strptime.m			\
       unicode.m			\
       ${USE_SRCS_PLUGINS}		\
       ${USE_SRCS_THREADS}
SRCS_PLUGINS = OFPlugin.m
SRCS_THREADS = OFCondition.m		\
	       OFMutex.m		\
	       OFRecursiveMutex.m	\
	       OFThread.m		\
	       OFThreadPool.m		\
	       OFTLSKey.m

INCLUDES_THREADS = threading.h
INCLUDES := ${SRCS:.m=.h}		\
	    OFCollection.h		\
	    OFHash.h			\
	    OFJSONRepresentation.h	\
	    OFLocking.h			\
	    OFSerialization.h		\
	    OFTLSSocket.h		\
	    ObjFW.h			\
	    asprintf.h			\
	    autorelease.h		\
	    ${ATOMIC_H}			\
	    block.h			\
	    instance.h			\
	    macros.h			\
	    objfw-defs.h		\
	    ${USE_INCLUDES_THREADS}

SRCS += OFArray_adjacent.m		\
	OFArray_adjacentSubarray.m	\
	${AUTORELEASE_M}		\
	${INSTANCE_M}			\
	OFCountedSet_hashtable.m	\
	OFDictionary_hashtable.m	\
	OFMutableArray_adjacent.m	\
	OFMutableDictionary_hashtable.m	\
	OFMutableSet_hashtable.m	\
	OFMutableString_UTF8.m		\
	OFSet_hashtable.m		\
	${OFSTREAMOBSERVER_KQUEUE_M}	\
	${OFSTREAMOBSERVER_POLL_M}	\
	${OFSTREAMOBSERVER_SELECT_M}	\
	OFString_UTF8.m			\
	OFTCPSocket+SOCKS5.m		\
	${APPLE_FORWARDING_S}		\
	${ASPRINTF_M}			\
	${FOUNDATION_COMPAT_M}		\
	iso_8859_15.m			\
	windows_1252.m

OBJS_EXTRA = ${EXCEPTIONS_EXCEPTIONS_A} ${RUNTIME_RUNTIME_A}
LIB_OBJS_EXTRA = ${EXCEPTIONS_EXCEPTIONS_LIB_A} ${RUNTIME_RUNTIME_LIB_A}

include ../buildsys.mk

CPPFLAGS += -I. -I.. -Iexceptions -Iruntime
LD = ${OBJC}
LDFLAGS += ${REEXPORT_LIBOBJC}

${BRIDGE}: ${SHARED_LIB}
