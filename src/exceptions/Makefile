include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${EXCEPTIONS_LIB_A}
STATIC_LIB_NOINST = ${EXCEPTIONS_A}

SRCS = OFAllocFailedException.m				\
       OFChangeCurrentDirectoryPathFailedException.m	\
       OFChecksumMismatchException.m			\
       OFCopyItemFailedException.m			\
       OFCreateDirectoryFailedException.m		\
       OFCreateSymbolicLinkFailedException.m		\
       OFEnumerationMutationException.m			\
       OFException.m					\
       OFGetOptionFailedException.m			\
       OFHashAlreadyCalculatedException.m		\
       OFInitializationFailedException.m		\
       OFInvalidArgumentException.m			\
       OFInvalidEncodingException.m			\
       OFInvalidFormatException.m			\
       OFInvalidJSONException.m				\
       OFInvalidServerReplyException.m			\
       OFLinkFailedException.m				\
       OFLockFailedException.m				\
       OFMalformedXMLException.m			\
       OFMemoryNotPartOfObjectException.m		\
       OFMoveItemFailedException.m			\
       OFNotImplementedException.m			\
       OFNotOpenException.m				\
       OFOpenItemFailedException.m			\
       OFOutOfMemoryException.m				\
       OFOutOfRangeException.m				\
       OFReadFailedException.m				\
       OFReadOrWriteFailedException.m			\
       OFRemoveItemFailedException.m			\
       OFRetrieveItemAttributesFailedException.m	\
       OFSandboxActivationFailedException.m		\
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
       ${USE_SRCS_SOCKETS}				\
       ${USE_SRCS_THREADS}				\
       ${USE_SRCS_PLUGINS}
SRCS_FILES = OFGetCurrentDirectoryPathFailedException.m
SRCS_SOCKETS = OFAcceptFailedException.m		\
	       OFAddressTranslationFailedException.m	\
	       OFAlreadyConnectedException.m		\
	       OFBindFailedException.m			\
	       OFConnectionFailedException.m		\
	       OFHTTPRequestFailedException.m		\
	       OFListenFailedException.m		\
	       OFObserveFailedException.m
SRCS_THREADS = OFConditionBroadcastFailedException.m	\
	       OFConditionSignalFailedException.m	\
	       OFConditionStillWaitingException.m	\
	       OFConditionWaitFailedException.m		\
	       OFThreadJoinFailedException.m		\
	       OFThreadStartFailedException.m		\
	       OFThreadStillRunningException.m
SRCS_PLUGINS = OFLoadPluginFailedException.m

INCLUDES = ${SRCS:.m=.h}

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../runtime
