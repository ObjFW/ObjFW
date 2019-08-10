include ../extra.mk

SUBDIRS = ${RUNTIME} exceptions ${ENCODINGS} forwarding invocation
SUBDIRS_AFTER = ${BRIDGE}
DISTCLEAN = objfw-defs.h

SHARED_LIB = ${OBJFW_SHARED_LIB}
STATIC_LIB = ${OBJFW_STATIC_LIB}
FRAMEWORK = ${OBJFW_FRAMEWORK}
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
       OFAutoreleasePool.m		\
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
       OFIntrospection.m		\
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
       ${OFPROCESS_M}			\
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
SRCS_PLUGINS = OFPlugin.m
SRCS_SOCKETS = OFDNSResolver.m			\
	       OFDNSResourceRecord.m		\
	       OFHTTPClient.m			\
	       OFHTTPCookie.m			\
	       OFHTTPCookieManager.m		\
	       OFHTTPRequest.m			\
	       OFHTTPResponse.m			\
	       OFHTTPServer.m			\
	       OFStreamSocket.m			\
	       OFTCPSocket.m			\
	       OFUDPSocket.m			\
	       socket.m
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
	    autorelease.h			\
	    block.h				\
	    instance.h				\
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
	${AUTORELEASE_M}		\
	${FOUNDATION_COMPAT_M}		\
	${INSTANCE_M}			\
	${LIBBASES_M}
SRCS_FILES += OFFileURLHandler.m	\
	      OFINIFileSettings.m
SRCS_SOCKETS += OFHTTPURLHandler.m			\
		OFKernelEventObserver.m			\
		${OFEPOLLKERNELEVENTOBSERVER_M}		\
		${OFKQUEUEKERNELEVENTOBSERVER_M}	\
		${OFPOLLKERNELEVENTOBSERVER_M}		\
		${OFSELECTKERNELEVENTOBSERVER_M}

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

include ../buildsys.mk

CPPFLAGS += -I. -I.. -Iexceptions -Iruntime
LD = ${OBJC}
FRAMEWORK_LIBS := -Fruntime				\
		  ${RUNTIME_FRAMEWORK_LIBS}		\
		  ${REEXPORT_RUNTIME_FRAMEWORK}		\
		  ${LIBS}
LIBS := -Lruntime ${RUNTIME_LIBS} ${REEXPORT_RUNTIME} ${LIBS}
