include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${EXCEPTIONS_LIB_A}
STATIC_LIB_NOINST = ${EXCEPTIONS_A}

SRCS = OFAllocFailedException.m				\
       OFChangeCurrentDirectoryPathFailedException.m	\
       OFChangeOwnerFailedException.m			\
       OFChangePermissionsFailedException.m		\
       OFChecksumFailedException.m			\
       OFCopyItemFailedException.m			\
       OFCreateDirectoryFailedException.m		\
       OFCreateSymbolicLinkFailedException.m		\
       OFEnumerationMutationException.m			\
       OFException.m					\
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
       OFNotImplementedException.m			\
       OFOpenFileFailedException.m			\
       OFOutOfMemoryException.m				\
       OFOutOfRangeException.m				\
       OFReadFailedException.m				\
       OFReadOrWriteFailedException.m			\
       OFRemoveItemFailedException.m			\
       OFRenameItemFailedException.m			\
       OFSeekFailedException.m				\
       OFSetOptionFailedException.m			\
       OFStillLockedException.m				\
       OFTruncatedDataException.m			\
       OFUnboundNamespaceException.m			\
       OFUnboundPrefixException.m			\
       OFUnlockFailedException.m			\
       OFUnsupportedProtocolException.m			\
       OFUnsupportedVersionException.m			\
       OFWriteFailedException.m				\
       ${USE_SRCS_SOCKETS}				\
       ${USE_SRCS_THREADS}
SRCS_SOCKETS = OFAcceptFailedException.m		\
	       OFAddressTranslationFailedException.m	\
	       OFAlreadyConnectedException.m		\
	       OFBindFailedException.m			\
	       OFConnectionFailedException.m		\
	       OFHTTPRequestFailedException.m		\
	       OFListenFailedException.m		\
	       OFNotConnectedException.m
SRCS_THREADS = OFConditionBroadcastFailedException.m	\
	       OFConditionSignalFailedException.m	\
	       OFConditionStillWaitingException.m	\
	       OFConditionWaitFailedException.m		\
	       OFThreadJoinFailedException.m		\
	       OFThreadStartFailedException.m		\
	       OFThreadStillRunningException.m

INCLUDES = ${SRCS:.m=.h}

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../.. -I../runtime
LD = ${OBJC}
