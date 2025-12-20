include ../extra.mk

SUBDIRS = ${RUNTIME} exceptions encodings forwarding
SUBDIRS_AFTER = ${BRIDGE} ${TLS} hid test
DISTCLEAN = Info.plist objfw-defs.h

SHARED_LIB = ${OBJFW_SHARED_LIB}
STATIC_LIB = ${OBJFW_STATIC_LIB}
FRAMEWORK = ${OBJFW_FRAMEWORK}
LIB_MAJOR = ${OBJFW_LIB_MAJOR}
LIB_MINOR = ${OBJFW_LIB_MINOR}
LIB_PATCH = ${OBJFW_LIB_PATCH}

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
       OFDeflate64Stream.m		\
       OFDeflateStream.m		\
       OFDictionary.m			\
       OFEmbeddedIRIHandler.m		\
       OFEnumerator.m			\
       OFFileManager.m			\
       OFGZIPStream.m			\
       OFHMAC.m				\
       OFINICategory.m			\
       OFINIFile.m			\
       OFINISection.m			\
       OFIRI.m				\
       OFIRIHandler.m			\
       OFImage.m			\
       OFImageFormatHandler.m		\
       OFIndexSet.m			\
       OFInvocation.m			\
       OFLHAArchive.m			\
       OFLHAArchiveEntry.m		\
       OFList.m				\
       OFLocale.m			\
       OFMD5Hash.m			\
       OFMapTable.m			\
       OFMatrix4x4.m			\
       OFMemoryStream.m			\
       OFMessagePackExtension.m		\
       OFMethodSignature.m		\
       OFMutableArray.m			\
       OFMutableData.m			\
       OFMutableDictionary.m		\
       OFMutableIRI.m			\
       OFMutableImage.m			\
       OFMutableIndexSet.m		\
       OFMutableLHAArchiveEntry.m	\
       OFMutablePair.m			\
       OFMutableSet.m			\
       OFMutableString.m		\
       OFMutableTarArchiveEntry.m	\
       OFMutableTriple.m		\
       OFMutableZIPArchiveEntry.m	\
       OFMutableZooArchiveEntry.m	\
       OFNotification.m			\
       OFNotificationCenter.m		\
       OFNull.m				\
       OFNumber.m			\
       OFObject.m			\
       OFObject+KeyValueCoding.m	\
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
       OFSet.m				\
       OFSettings.m			\
       OFSortedList.m			\
       OFStdIOStream.m			\
       OFStream.m			\
       OFString.m			\
       OFString+CryptographicHashing.m	\
       OFString+JSONParsing.m		\
       OFString+PercentEncoding.m	\
       OFString+PropertyListParsing.m	\
       OFString+XMLEscaping.m		\
       OFString+XMLUnescaping.m		\
       OFSystemInfo.m			\
       OFTarArchive.m			\
       OFTarArchiveEntry.m		\
       OFThread.m			\
       OFTimer.m			\
       OFTriple.m			\
       OFUUID.m				\
       OFValue.m			\
       OFXMLAttribute.m			\
       OFXMLCDATA.m			\
       OFXMLCharacters.m		\
       OFXMLComment.m			\
       OFXMLElement.m			\
       OFXMLElementBuilder.m		\
       OFXMLNode.m			\
       OFXMLParser.m			\
       OFXMLProcessingInstruction.m	\
       OFZIPArchive.m			\
       OFZIPArchiveEntry.m		\
       OFZooArchive.m			\
       OFZooArchiveEntry.m		\
       ${USE_SRCS_FILES}		\
       ${USE_SRCS_MODULES}		\
       ${USE_SRCS_SOCKETS}		\
       ${USE_SRCS_SUBPROCESSES}		\
       ${USE_SRCS_THREADS}		\
       ${USE_SRCS_WINDOWS}
SRCS_FILES = OFFile.m			\
	     OFString+PathAdditions.m
SRCS_MODULES = OFPlugin.m	\
	       OFModule.m
SRCS_SOCKETS = OFAAAADNSResourceRecord.m	\
	       OFADNSResourceRecord.m		\
	       OFCNAMEDNSResourceRecord.m	\
	       OFDNSQuery.m			\
	       OFDNSResolver.m			\
	       OFDNSResourceRecord.m		\
	       OFDNSResponse.m			\
	       OFDatagramSocket.m		\
	       OFHINFODNSResourceRecord.m	\
	       OFHTTPClient.m			\
	       OFHTTPCookie.m			\
	       OFHTTPCookieManager.m		\
	       OFHTTPRequest.m			\
	       OFHTTPResponse.m			\
	       OFHTTPServer.m			\
	       OFLOCDNSResourceRecord.m		\
	       OFMXDNSResourceRecord.m		\
	       OFNSDNSResourceRecord.m		\
	       OFPTRDNSResourceRecord.m		\
	       OFRPDNSResourceRecord.m		\
	       OFSOADNSResourceRecord.m		\
	       OFSRVDNSResourceRecord.m		\
	       OFSequencedPacketSocket.m	\
	       OFSocket.m			\
	       OFStreamSocket.m			\
	       OFSystemInfo+NetworkInterfaces.m	\
	       OFTCPSocket.m			\
	       OFTLSStream.m			\
	       OFTXTDNSResourceRecord.m		\
	       OFUDPSocket.m			\
	       OFURIDNSResourceRecord.m		\
	       OFX509Certificate.m		\
	       ${USE_SRCS_APPLETALK}		\
	       ${USE_SRCS_IPX}			\
	       ${USE_SRCS_SCTP}			\
	       ${USE_SRCS_UNIX_SOCKETS}
SRCS_APPLETALK = OFDDPSocket.m
SRCS_IPX = OFIPXSocket.m	\
	   OFSPXSocket.m	\
	   OFSPXStreamSocket.m
SRCS_SCTP = OFSCTPSocket.m
SRCS_UNIX_SOCKETS = OFUNIXDatagramSocket.m		\
		    OFUNIXSequencedPacketSocket.m	\
		    OFUNIXStreamSocket.m
SRCS_SUBPROCESSES = OFSubprocess.m
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
	    OFInflate64Stream.h			\
	    OFInflateStream.h			\
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
	OFArchiveIRIHandler.m		\
	OFBMPImageFormatHandler.m	\
	OFBase64.m			\
	OFBitSetCharacterSet.m		\
	OFCRC16.m			\
	OFCRC32.m			\
	OFConcreteArray.m		\
	OFConcreteColor.m		\
	OFConcreteCountedSet.m		\
	OFConcreteData.m		\
	OFConcreteDate.m		\
	OFConcreteDictionary.m		\
	OFConcreteImage.m		\
	OFConcreteMutableArray.m	\
	OFConcreteMutableData.m		\
	OFConcreteMutableDictionary.m	\
	OFConcreteMutableImage.m	\
	OFConcreteMutableSet.m		\
	OFConcreteNumber.m		\
	OFConcreteSet.m			\
	OFConcreteSubarray.m		\
	OFConcreteValue.m		\
	OFHuffmanTree.m			\
	OFINIFileSettings.m		\
	OFInvertedCharacterSet.m	\
	OFLHADecompressingStream.m	\
	OFMutableUTF8String.m		\
	OFQOIImageFormatHandler.m	\
	OFRangeCharacterSet.m		\
	OFSandbox.m			\
	OFStrFTime.m			\
	OFStrPTime.m			\
	OFSubarray.m			\
	OFSubdata.m			\
	OFUTF8String.m			\
	${AUTORELEASE_FOUNDATION_M}	\
	${LIBBASES_M}			\
	${RUNTIME_ARC_M}		\
	${RUNTIME_ASSOCIATION_M}	\
	${RUNTIME_INSTANCE_M}		\
	${UNICODE_M}			\
	${USE_SRCS_TAGGED_POINTERS}
SRCS_FILES += OFFileIRIHandler.m
SRCS_SOCKETS += OFAsyncIPSocketConnector.m		\
		OFDNSResolverSettings.m			\
		${OF_EPOLL_KERNEL_EVENT_OBSERVER_M}	\
		OFHTTPIRIHandler.m			\
		OFHostAddressResolver.m			\
		OFKernelEventObserver.m			\
		${OF_KQUEUE_KERNEL_EVENT_OBSERVER_M}	\
		${OF_POLL_KERNEL_EVENT_OBSERVER_M}	\
		${OF_SELECT_KERNEL_EVENT_OBSERVER_M}	\
		OFTCPSocketSOCKS5Connector.m
SRCS_TAGGED_POINTERS = OFTaggedPointerColor.m		\
		       OFTaggedPointerDate.m		\
		       OFTaggedPointerNumber.m		\
		       OFTaggedPointerString.m
SRCS_WINDOWS += platform/Windows/OFWin32ConsoleStdIOStream.m	\
		versioninfo.rc

OBJS_EXTRA = exceptions/exceptions.a	\
	     encodings/encodings.a	\
	     forwarding/forwarding.a
LIB_OBJS_EXTRA = exceptions/exceptions.lib.a	\
		 encodings/encodings.lib.a	\
		 forwarding/forwarding.lib.a

include ../buildsys.mk

${TLS} hid: ${BRIDGE}

CPPFLAGS += -I. -I.. -Iexceptions -Iruntime
LD = ${OBJC}
FRAMEWORK_LIBS := -Fruntime				\
		  ${RUNTIME_FRAMEWORK_LIBS}		\
		  ${REEXPORT_RUNTIME_FRAMEWORK}		\
		  ${LIBS}
LIBS := -Lruntime -Lruntime/linklib ${RUNTIME_LIBS} ${REEXPORT_RUNTIME} ${LIBS}
RCFLAGS = --use-temp-file						\
	  -DOBJFW_LIB_MAJOR=${OBJFW_LIB_MAJOR}				\
	  -DOBJFW_LIB_MINOR=${OBJFW_LIB_MINOR}				\
	  -DOBJFW_LIB_VERSION=\"${OBJFW_LIB_MAJOR}.${OBJFW_LIB_MINOR}\" \
	  -DOBJFW_SHARED_LIB=\"${OBJFW_SHARED_LIB}\"

uninstall-extra:
	for i in platform/GCC4 platform/GCC4.7 platform/PowerPC platform/macOS \
	    platform/x86 platform ""; do \
		if test -d ${DESTDIR}${includedir}/${includesubdir}/$$i; then \
			rmdir ${DESTDIR}${includedir}/${includesubdir}/$$i; \
		fi; \
	done
