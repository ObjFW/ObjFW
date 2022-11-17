include ../extra.mk

SUBDIRS = ${RUNTIME} exceptions encodings forwarding
SUBDIRS_AFTER = ${LINKLIB} ${BRIDGE} ${TLS}
CLEAN = amiga-end.amigalib.dep		\
	amiga-end.amigalib.o		\
	amiga-glue.amigalib.dep		\
	amiga-glue.amigalib.o		\
	amiga-library-functable.inc	\
	amiga-library.amigalib.dep	\
	amiga-library.amigalib.o
DISTCLEAN = Info.plist objfw-defs.h

SHARED_LIB = ${OBJFW_SHARED_LIB}
STATIC_LIB = ${OBJFW_STATIC_LIB}
FRAMEWORK = ${OBJFW_FRAMEWORK}
AMIGA_LIB = ${OBJFW_AMIGA_LIB}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}

SRCS = OFApplication.m			\
       OFArray.m			\
       OFBlock.m			\
       OFCharacterSet.m			\
       OFColor.m			\
       OFConstantString.m		\
       OFCountedSet.m			\
       OFData.m				\
       OFData+CryptographicHashing.m	\
       OFData+MessagePackParsing.m	\
       OFDate.m				\
       OFDictionary.m			\
       OFEmbeddedURIHandler.m		\
       OFEnumerator.m			\
       OFFileManager.m			\
       OFGZIPStream.m			\
       OFHMAC.m				\
       OFINICategory.m			\
       OFINIFile.m			\
       OFInflate64Stream.m		\
       OFInflateStream.m		\
       OFInvocation.m			\
       OFLHAArchive.m			\
       OFLHAArchiveEntry.m		\
       OFList.m				\
       OFLocale.m			\
       OFMD5Hash.m			\
       OFMapTable.m			\
       OFMemoryStream.m			\
       OFMessagePackExtension.m		\
       OFMethodSignature.m		\
       OFMutableArray.m			\
       OFMutableData.m			\
       OFMutableDictionary.m		\
       OFMutableLHAArchiveEntry.m	\
       OFMutablePair.m			\
       OFMutableSet.m			\
       OFMutableString.m		\
       OFMutableTarArchiveEntry.m	\
       OFMutableTriple.m		\
       OFMutableURI.m			\
       OFMutableZIPArchiveEntry.m	\
       OFNotification.m			\
       OFNotificationCenter.m		\
       OFNull.m				\
       OFNumber.m			\
       OFObject.m			\
       OFObject+KeyValueCoding.m	\
       OFObject+Serialization.m		\
       OFOnce.m				\
       OFOptionsParser.m		\
       OFPBKDF2.m			\
       OFPair.m				\
       OFRIPEMD160Hash.m		\
       OFRunLoop.m			\
       OFSHA1Hash.m			\
       OFSHA224Hash.m			\
       OFSHA224Or256Hash.m		\
       OFSHA256Hash.m			\
       OFSHA384Hash.m			\
       OFSHA384Or512Hash.m		\
       OFSHA512Hash.m			\
       OFScrypt.m			\
       OFSecureData.m			\
       OFSeekableStream.m		\
       OFSerialization.m		\
       OFSet.m				\
       OFSortedList.m			\
       OFStdIOStream.m			\
       OFStream.m			\
       OFString.m			\
       OFString+CryptographicHashing.m	\
       OFString+JSONParsing.m		\
       OFString+PercentEncoding.m	\
       OFString+PropertyListParsing.m	\
       OFString+Serialization.m		\
       OFString+XMLEscaping.m		\
       OFString+XMLUnescaping.m		\
       ${OF_SUBPROCESS_M}		\
       OFSettings.m			\
       OFSystemInfo.m			\
       OFTarArchive.m			\
       OFTarArchiveEntry.m		\
       OFThread.m			\
       OFTimer.m			\
       OFTriple.m			\
       OFURI.m				\
       OFURIHandler.m			\
       OFUUID.m				\
       OFValue.m			\
       OFXMLAttribute.m			\
       OFXMLCDATA.m			\
       OFXMLCharacters.m		\
       OFXMLComment.m			\
       OFXMLElement.m			\
       OFXMLElement+Serialization.m	\
       OFXMLElementBuilder.m		\
       OFXMLNode.m			\
       OFXMLParser.m			\
       OFXMLProcessingInstruction.m	\
       OFZIPArchive.m			\
       OFZIPArchiveEntry.m		\
       ${USE_SRCS_FILES}		\
       ${USE_SRCS_PLUGINS}		\
       ${USE_SRCS_SOCKETS}		\
       ${USE_SRCS_THREADS}		\
       ${USE_SRCS_WINDOWS}
SRCS_FILES = OFFile.m			\
	     OFString+PathAdditions.m
SRCS_PLUGINS = OFPlugin.m
SRCS_SOCKETS = OFDNSQuery.m			\
	       OFDNSResolver.m			\
	       OFDNSResourceRecord.m		\
	       OFDNSResponse.m			\
	       OFDatagramSocket.m		\
	       OFHTTPClient.m			\
	       OFHTTPCookie.m			\
	       OFHTTPCookieManager.m		\
	       OFHTTPRequest.m			\
	       OFHTTPResponse.m			\
	       OFHTTPServer.m			\
	       OFSequencedPacketSocket.m	\
	       OFSocket.m			\
	       OFStreamSocket.m			\
	       OFTCPSocket.m			\
	       OFTLSStream.m			\
	       OFUDPSocket.m			\
	       ${USE_SRCS_APPLETALK}		\
	       ${USE_SRCS_IPX}			\
	       ${USE_SRCS_UNIX_SOCKETS}
SRCS_APPLETALK = OFDDPSocket.m
SRCS_IPX = OFIPXSocket.m	\
	   OFSPXSocket.m	\
	   OFSPXStreamSocket.m
SRCS_UNIX_SOCKETS = OFUNIXDatagramSocket.m	\
		    OFUNIXStreamSocket.m
SRCS_THREADS = OFCondition.m		\
	       OFMutex.m		\
	       OFPlainCondition.m	\
	       OFPlainMutex.m		\
	       OFPlainThread.m		\
	       OFRecursiveMutex.m	\
	       OFTLSKey.m
SRCS_WINDOWS = OFWindowsRegistryKey.m

INCLUDES_ATOMIC = OFAtomic.h			\
		  platform/GCC4/OFAtomic.h	\
		  platform/GCC4.7/OFAtomic.h	\
		  platform/PowerPC/OFAtomic.h	\
		  platform/macOS/OFAtomic.h	\
		  platform/x86/OFAtomic.h
INCLUDES := ${SRCS:.m=.h}			\
	    OFArchiveEntry.h			\
	    OFCollection.h			\
	    OFCryptographicHash.h		\
	    OFJSONRepresentation.h		\
	    OFKernelEventObserver.h		\
	    OFKeyValueCoding.h			\
	    OFLocking.h				\
	    OFMessagePackRepresentation.h	\
	    OFMutableArchiveEntry.h		\
	    ObjFW.h				\
	    macros.h				\
	    objfw-defs.h			\
	    platform.h				\
	    ${USE_INCLUDES_ATOMIC}

SRCS += OFASPrintF.m			\
	OFAdjacentArray.m		\
	OFAdjacentSubarray.m		\
	OFArchiveURIHandler.m		\
	OFBase64.m			\
	OFBitSetCharacterSet.m		\
	OFBytesValue.m			\
	OFCRC16.m			\
	OFCRC32.m			\
	OFCountedMapTableSet.m		\
	OFHuffmanTree.m			\
	OFINIFileSettings.m		\
	OFInvertedCharacterSet.m	\
	OFLHADecompressingStream.m	\
	OFMapTableDictionary.m		\
	OFMapTableSet.m			\
	OFMutableAdjacentArray.m	\
	OFMutableMapTableDictionary.m	\
	OFMutableMapTableSet.m		\
	OFMutableUTF8String.m		\
	OFNonretainedObjectValue.m	\
	OFPointValue.m			\
	OFPointerValue.m		\
	OFRangeCharacterSet.m		\
	OFRangeValue.m			\
	OFRectValue.m			\
	OFSandbox.m			\
	OFSizeValue.m			\
	OFStrPTime.m			\
	OFSubarray.m			\
	OFUTF8String.m			\
	${LIBBASES_M}			\
	${RUNTIME_AUTORELEASE_M}	\
	${RUNTIME_INSTANCE_M}		\
	${UNICODE_M}
SRCS_FILES += OFFileURIHandler.m
SRCS_SOCKETS += OFAsyncIPSocketConnector.m		\
		OFDNSResolverSettings.m			\
		${OF_EPOLL_KERNEL_EVENT_OBSERVER_M}	\
		OFHTTPURIHandler.m			\
		OFHostAddressResolver.m			\
		OFKernelEventObserver.m			\
		${OF_KQUEUE_KERNEL_EVENT_OBSERVER_M}	\
		${OF_POLL_KERNEL_EVENT_OBSERVER_M}	\
		${OF_SELECT_KERNEL_EVENT_OBSERVER_M}	\
		OFTCPSocketSOCKS5Connector.m
SRCS_WINDOWS += platform/Windows/OFWin32ConsoleStdIOStream.m	\
		versioninfo.rc

OBJS_EXTRA = exceptions/exceptions.a	\
	     encodings/encodings.a	\
	     forwarding/forwarding.a
LIB_OBJS_EXTRA = exceptions/exceptions.lib.a	\
		 encodings/encodings.lib.a	\
		 forwarding/forwarding.lib.a
AMIGA_LIB_OBJS_START = amiga-library.amigalib.o
AMIGA_LIB_OBJS_EXTRA = amiga-glue.amigalib.o		\
		       exceptions/exceptions.amigalib.a	\
		       encodings/encodings.amigalib.a	\
		       forwarding/forwarding.amigalib.a	\
		       amiga-end.amigalib.o

include ../buildsys.mk

CPPFLAGS += -I. -I.. -Iexceptions -Iruntime		\
	    -DOBJFW_AMIGA_LIB=\"${OBJFW_AMIGA_LIB}\"	\
	    -DOBJFW_LIB_MAJOR=${OBJFW_LIB_MAJOR}	\
	    -DOBJFW_LIB_MINOR=${OBJFW_LIB_MINOR}
AMIGA_LIB_CFLAGS += -DOF_COMPILING_AMIGA_LIBRARY
LD = ${OBJC}
FRAMEWORK_LIBS := -Fruntime				\
		  ${RUNTIME_FRAMEWORK_LIBS}		\
		  ${REEXPORT_RUNTIME_FRAMEWORK}		\
		  ${LIBS}
LIBS := -Lruntime -Lruntime/linklib ${RUNTIME_LIBS} ${REEXPORT_RUNTIME} ${LIBS}
AMIGA_LIB_LIBS = ${LIBS}
RCFLAGS = --use-temp-file						\
	  -DOBJFW_LIB_MAJOR=${OBJFW_LIB_MAJOR}				\
	  -DOBJFW_LIB_MINOR=${OBJFW_LIB_MINOR}				\
	  -DOBJFW_LIB_VERSION=\"${OBJFW_LIB_MAJOR}.${OBJFW_LIB_MINOR}\" \
	  -DOBJFW_SHARED_LIB=\"${OBJFW_SHARED_LIB}\"
