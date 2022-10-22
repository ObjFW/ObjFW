include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${EXCEPTIONS_LIB_A}
STATIC_LIB_NOINST = ${EXCEPTIONS_A}

SRCS = OFAllocFailedException.m				\
       OFChecksumMismatchException.m			\
       OFCopyItemFailedException.m			\
       OFCreateDirectoryFailedException.m		\
       OFCreateSymbolicLinkFailedException.m		\
       OFEnumerationMutationException.m			\
       OFException.m					\
       OFGetItemAttributesFailedException.m		\
       OFGetOptionFailedException.m			\
       OFHashAlreadyCalculatedException.m		\
       OFHashNotCalculatedException.m			\
       OFInitializationFailedException.m		\
       OFInvalidArgumentException.m			\
       OFInvalidEncodingException.m			\
       OFInvalidFormatException.m			\
       OFInvalidJSONException.m				\
       OFInvalidServerResponseException.m		\
       OFLinkItemFailedException.m			\
       OFLockFailedException.m				\
       OFMalformedXMLException.m			\
       OFMoveItemFailedException.m			\
       OFNotImplementedException.m			\
       OFNotOpenException.m				\
       OFOpenItemFailedException.m			\
       OFOutOfMemoryException.m				\
       OFOutOfRangeException.m				\
       OFReadFailedException.m				\
       OFReadOrWriteFailedException.m			\
       OFRemoveItemFailedException.m			\
       OFSeekFailedException.m				\
       OFSetItemAttributesFailedException.m		\
       OFSetOptionFailedException.m			\
       OFStillLockedException.m				\
       OFTruncatedDataException.m			\
       OFUnboundNamespaceException.m			\
       OFUnboundPrefixException.m			\
       OFUndefinedKeyException.m			\
       OFUnknownXMLEntityException.m			\
       OFUnlockFailedException.m			\
       OFUnsupportedProtocolException.m			\
       OFUnsupportedVersionException.m			\
       OFWriteFailedException.m				\
       ${USE_SRCS_FILES}				\
       ${USE_SRCS_PLUGINS}				\
       ${USE_SRCS_SOCKETS}				\
       ${USE_SRCS_THREADS}				\
       ${USE_SRCS_WINDOWS}
SRCS_FILES = OFChangeCurrentDirectoryFailedException.m	\
	     OFGetCurrentDirectoryFailedException.m
SRCS_PLUGINS = OFLoadPluginFailedException.m
SRCS_SOCKETS = OFAcceptSocketFailedException.m		\
	       OFAlreadyConnectedException.m		\
	       OFBindIPSocketFailedException.m		\
	       OFBindSocketFailedException.m		\
	       OFConnectIPSocketFailedException.m	\
	       OFConnectSocketFailedException.m		\
	       OFDNSQueryFailedException.m		\
	       OFHTTPRequestFailedException.m		\
	       OFListenOnSocketFailedException.m	\
	       OFObserveKernelEventsFailedException.m	\
	       OFResolveHostFailedException.m		\
	       OFTLSHandshakeFailedException.m		\
	       ${USE_SRCS_APPLETALK}			\
	       ${USE_SRCS_IPX}				\
	       ${USE_SRCS_UNIX_SOCKETS}
SRCS_APPLETALK = OFBindDDPSocketFailedException.m
SRCS_IPX = OFBindIPXSocketFailedException.m	\
	   OFConnectSPXSocketFailedException.m
SRCS_UNIX_SOCKETS = OFBindUNIXSocketFailedException.m		\
		    OFConnectUNIXSocketFailedException.m
SRCS_THREADS = OFConditionBroadcastFailedException.m	\
	       OFConditionSignalFailedException.m	\
	       OFConditionStillWaitingException.m	\
	       OFConditionWaitFailedException.m		\
	       OFThreadJoinFailedException.m		\
	       OFThreadStartFailedException.m		\
	       OFThreadStillRunningException.m
SRCS_WINDOWS = OFCreateWindowsRegistryKeyFailedException.m	\
	       OFDeleteWindowsRegistryKeyFailedException.m	\
	       OFDeleteWindowsRegistryValueFailedException.m	\
	       OFGetWindowsRegistryValueFailedException.m	\
	       OFOpenWindowsRegistryKeyFailedException.m	\
	       OFSetWindowsRegistryValueFailedException.m

INCLUDES := ${SRCS:.m=.h}

SRCS += OFSandboxActivationFailedException.m

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../runtime
