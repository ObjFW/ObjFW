include ../extra.mk

SUBDIRS = ${RUNTIME} exceptions ${ENCODINGS} forwarding invocation
SUBDIRS_AFTER = ${BRIDGE}
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

SRCS = OFASN1BitString.m		\
       OFASN1Boolean.m			\
       OFASN1Enumerated.m		\
       OFASN1IA5String.m		\
       OFASN1Integer.m			\
       OFASN1NumericString.m		\
       OFASN1ObjectIdentifier.m		\
       OFASN1OctetString.m		\
       OFASN1PrintableString.m		\
       OFASN1UTF8String.m		\
       OFASN1Value.m			\
       OFApplication.m			\
       OFArray.m			\
       OFBlock.m			\
       OFCharacterSet.m			\
       OFColor.m			\
       OFConstantString.m		\
       OFCountedSet.m			\
       OFData.m				\
       OFData+ASN1DERValue.m		\
       OFData+CryptoHashing.m		\
       OFData+MessagePackValue.m	\
       OFDate.m				\
       OFDictionary.m			\
       OFEnumerator.m			\
       OFFileManager.m			\
       OFGZIPStream.m			\
       OFHMAC.m				\
       OFInflate64Stream.m		\
       OFInflateStream.m		\
       OFInvocation.m			\
       OFLHAArchive.m			\
       OFLHAArchiveEntry.m		\
       OFList.m				\
       OFLocale.m			\
       OFMapTable.m			\
       OFMD5Hash.m			\
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
       OFMutableURL.m			\
       OFMutableZIPArchiveEntry.m	\
       OFNull.m				\
       OFNumber.m			\
       OFObject.m			\
       OFObject+KeyValueCoding.m	\
       OFObject+Serialization.m		\
       OFOptionsParser.m		\
       OFPair.m				\
       ${OF_PROCESS_M}			\
       OFRIPEMD160Hash.m		\
       OFRunLoop.m			\
       OFSandbox.m			\
       OFSecureData.m			\
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
       OFStream.m			\
       OFString.m			\
       OFString+CryptoHashing.m		\
       OFString+JSONValue.m		\
       OFString+PropertyListValue.m	\
       OFString+Serialization.m		\
       OFString+URLEncoding.m		\
       OFString+XMLEscaping.m		\
       OFString+XMLUnescaping.m		\
       OFSystemInfo.m			\
       OFTarArchive.m			\
       OFTarArchiveEntry.m		\
       OFThread.m			\
       OFTimer.m			\
       OFTriple.m			\
       OFURL.m				\
       OFURLHandler.m			\
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
       OFXMLProcessingInstructions.m	\
       OFZIPArchive.m			\
       OFZIPArchiveEntry.m		\
       base64.m				\
       crc16.m				\
       crc32.m				\
       huffman_tree.m			\
       of_asprintf.m			\
       of_strptime.m			\
       once.m				\
       pbkdf2.m				\
       scrypt.m				\
       ${UNICODE_M}			\
       ${USE_SRCS_FILES}		\
       ${USE_SRCS_PLUGINS}		\
       ${USE_SRCS_SOCKETS}		\
       ${USE_SRCS_THREADS}		\
       ${USE_SRCS_WINDOWS}
SRCS_FILES = OFFile.m			\
	     OFINICategory.m		\
	     OFINIFile.m		\
	     OFSettings.m		\
	     OFString+PathAdditions.m
SRCS_IPX = OFIPXSocket.m	\
	   OFSPXSocket.m	\
	   OFSPXStreamSocket.m
SRCS_PLUGINS = OFPlugin.m
SRCS_SCTP = OFSCTPSocket.m
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
	       OFStreamSocket.m			\
	       OFTCPSocket.m			\
	       OFUDPSocket.m			\
	       socket.m				\
	       ${USE_SRCS_IPX}			\
	       ${USE_SRCS_SCTP}
SRCS_THREADS = OFCondition.m		\
	       OFMutex.m		\
	       OFRecursiveMutex.m	\
	       OFThreadPool.m		\
	       condition.m		\
	       mutex.m			\
	       thread.m			\
	       tlskey.m
SRCS_WINDOWS = OFWin32ConsoleStdIOStream.m	\
	       OFWindowsRegistryKey.m

INCLUDES_ATOMIC = atomic.h			\
		  atomic_builtins.h		\
		  atomic_no_threads.h		\
		  atomic_osatomic.h		\
		  atomic_powerpc.h		\
		  atomic_sync_builtins.h	\
		  atomic_x86.h
INCLUDES := ${SRCS:.m=.h}			\
	    OFASN1DERRepresentation.h		\
	    OFCollection.h			\
	    OFCryptoHash.h			\
	    OFJSONRepresentation.h		\
	    OFKernelEventObserver.h		\
	    OFKeyValueCoding.h			\
	    OFLocking.h				\
	    OFMessagePackRepresentation.h	\
	    OFSerialization.h			\
	    OFTLSSocket.h			\
	    ObjFW.h				\
	    block.h				\
	    macros.h				\
	    objfw-defs.h			\
	    platform.h				\
	    ${USE_INCLUDES_ATOMIC}

SRCS += OFAdjacentArray.m		\
	OFAdjacentSubarray.m		\
	OFBitSetCharacterSet.m		\
	OFBytesValue.m			\
	OFCountedMapTableSet.m		\
	OFDimensionValue.m		\
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
	OFRectangleValue.m		\
	OFSubarray.m			\
	OFUTF8String.m			\
	${LIBBASES_M}
SRCS_FILES += OFFileURLHandler.m	\
	      OFINIFileSettings.m
SRCS_SOCKETS += OFDNSResolverSettings.m			\
		OFHTTPURLHandler.m			\
		OFHostAddressResolver.m			\
		OFIPSocketAsyncConnector.m		\
		OFKernelEventObserver.m			\
		${OF_EPOLL_KERNEL_EVENT_OBSERVER_M}	\
		${OF_KQUEUE_KERNEL_EVENT_OBSERVER_M}	\
		${OF_POLL_KERNEL_EVENT_OBSERVER_M}	\
		${OF_SELECT_KERNEL_EVENT_OBSERVER_M}	\
		OFTCPSocketSOCKS5Connector.m

OBJS_EXTRA = ${RUNTIME_RUNTIME_A}	\
	     ${EXCEPTIONS_EXCEPTIONS_A} \
	     ${ENCODINGS_ENCODINGS_A}	\
	     ${FORWARDING_FORWARDING_A}	\
	     ${INVOCATION_INVOCATION_A}
LIB_OBJS_EXTRA = ${RUNTIME_RUNTIME_LIB_A}	\
		 ${EXCEPTIONS_EXCEPTIONS_LIB_A}	\
		 ${ENCODINGS_ENCODINGS_LIB_A}	\
		 ${FORWARDING_FORWARDING_LIB_A}	\
		 ${INVOCATION_INVOCATION_LIB_A}
AMIGA_LIB_OBJS_START = amiga-library.amigalib.o
AMIGA_LIB_OBJS_EXTRA = amiga-glue.amigalib.o			\
		       ${EXCEPTIONS_EXCEPTIONS_AMIGALIB_A}	\
		       ${ENCODINGS_ENCODINGS_AMIGALIB_A}	\
		       ${FORWARDING_FORWARDING_AMIGALIB_A}	\
		       ${INVOCATION_INVOCATION_AMIGALIB_A}	\
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
