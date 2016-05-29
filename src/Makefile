include ../extra.mk

SUBDIRS = ${RUNTIME} exceptions forwarding
SUBDIRS_AFTER = ${BRIDGE}
DISTCLEAN = objfw-defs.h

SHARED_LIB = ${OBJFW_SHARED_LIB}
STATIC_LIB = ${OBJFW_STATIC_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFApplication.m			\
       OFArray.m			\
       OFArray_subarray.m		\
       OFAutoreleasePool.m		\
       OFBigDataArray.m			\
       OFBlock.m			\
       OFConstantString.m		\
       OFCountedSet.m			\
       OFDataArray.m			\
       OFDataArray+Hashing.m		\
       OFDataArray+MessagePackValue.m	\
       OFDate.m				\
       OFDeflateStream.m		\
       OFDeflate64Stream.m		\
       OFDictionary.m			\
       OFEnumerator.m			\
       OFGZIPStream.m			\
       OFIntrospection.m		\
       OFList.m				\
       OFMapTable.m			\
       OFMD5Hash.m			\
       OFMessagePackExtension.m		\
       OFMutableArray.m			\
       OFMutableDictionary.m		\
       OFMutableSet.m			\
       OFMutableString.m		\
       OFNull.m				\
       OFNumber.m			\
       OFObject.m			\
       OFObject+Serialization.m		\
       OFOptionsParser.m		\
       ${OFPROCESS_M}			\
       OFRIPEMD160Hash.m		\
       OFRunLoop.m			\
       OFSeekableStream.m		\
       OFSet.m				\
       OFSHA1Hash.m			\
       OFSHA224Hash.m			\
       OFSHA224Or256Hash.m		\
       OFSHA256Hash.m			\
       OFSHA384Hash.m			\
       OFSHA384Or512Hash.m		\
       OFSHA512Hash.m			\
       OFSortedList.m			\
       OFStdIOStream.m			\
       ${OFSTDIOSTREAM_WIN32CONSOLE_M}	\
       OFStream.m			\
       OFString.m			\
       OFString+Hashing.m		\
       OFString+JSONValue.m		\
       OFString+Serialization.m		\
       OFString+URLEncoding.m		\
       OFString+XMLEscaping.m		\
       OFString+XMLUnescaping.m		\
       OFSystemInfo.m			\
       OFTarArchive.m			\
       OFTarArchiveEntry.m		\
       OFThread.m			\
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
       OFZIPArchive.m			\
       OFZIPArchiveEntry.m		\
       base64.m				\
       crc32.m				\
       of_asprintf.m			\
       of_strptime.m			\
       unicode.m			\
       ${USE_SRCS_FILES}		\
       ${USE_SRCS_PLUGINS}		\
       ${USE_SRCS_SOCKETS}		\
       ${USE_SRCS_THREADS}
SRCS_FILES = OFFile.m			\
	     OFFileManager.m		\
	     OFINICategory.m		\
	     OFINIFile.m		\
	     OFSettings.m
SRCS_PLUGINS = OFPlugin.m
SRCS_SOCKETS = OFHTTPClient.m			\
	       OFHTTPRequest.m			\
	       OFHTTPResponse.m			\
	       OFHTTPServer.m			\
	       OFKernelEventObserver.m		\
	       OFStreamSocket.m			\
	       OFTCPSocket.m			\
	       OFUDPSocket.m			\
	       resolver.m			\
	       socket.m
SRCS_THREADS = OFCondition.m		\
	       OFMutex.m		\
	       OFRecursiveMutex.m	\
	       OFThreadPool.m		\
	       threading.m

INCLUDES := ${SRCS:.m=.h}			\
	    OFCollection.h			\
	    OFHash.h				\
	    OFJSONRepresentation.h		\
	    OFLocking.h				\
	    OFMessagePackRepresentation.h	\
	    OFSerialization.h			\
	    OFTLSSocket.h			\
	    ObjFW.h				\
	    autorelease.h			\
	    ${ATOMIC_H}				\
	    block.h				\
	    instance.h				\
	    macros.h				\
	    objfw-defs.h			\
	    platform.h

SRCS += OFArray_adjacent.m		\
	OFArray_adjacentSubarray.m	\
	OFCountedSet_hashtable.m	\
	OFDictionary_hashtable.m	\
	OFMutableArray_adjacent.m	\
	OFMutableDictionary_hashtable.m	\
	OFMutableSet_hashtable.m	\
	OFMutableString_UTF8.m		\
	OFSet_hashtable.m		\
	OFString_UTF8.m			\
	${AUTORELEASE_M}		\
	codepage_437.m			\
	${FOUNDATION_COMPAT_M}		\
	${INSTANCE_M}			\
	iso_8859_15.m			\
	windows_1252.m
SRCS_FILES += OFSettings_INIFile.m
SRCS_SOCKETS += ${OFKERNELEVENTOBSERVER_EPOLL_M}	\
		${OFKERNELEVENTOBSERVER_KQUEUE_M}	\
		${OFKERNELEVENTOBSERVER_POLL_M}		\
		${OFKERNELEVENTOBSERVER_SELECT_M}	\
		OFTCPSocket+SOCKS5.m

OBJS_EXTRA = ${RUNTIME_RUNTIME_A}	\
	     ${EXCEPTIONS_EXCEPTIONS_A} \
	     ${FORWARDING_FORWARDING_A}
LIB_OBJS_EXTRA = ${RUNTIME_RUNTIME_LIB_A}	\
		 ${EXCEPTIONS_EXCEPTIONS_LIB_A}	\
		 ${FORWARDING_FORWARDING_LIB_A}

include ../buildsys.mk

CPPFLAGS += -I. -I.. -Iexceptions -Iruntime
LD = ${OBJC}
LDFLAGS += ${REEXPORT_LIBOBJC}
