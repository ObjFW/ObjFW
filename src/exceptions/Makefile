include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${EXCEPTIONS_LIB_A}
STATIC_LIB_NOINST = ${EXCEPTIONS_A}

SRCS = OFAcceptFailedException.m		\
       OFAddressTranslationFailedException.m	\
       OFAllocFailedException.m			\
       OFAlreadyConnectedException.m		\
       OFBindFailedException.m			\
       OFChangeDirectoryFailedException.m	\
       OFChangeFileModeFailedException.m	\
       OFChangeFileOwnerFailedException.m	\
       OFConditionBroadcastFailedException.m	\
       OFConditionSignalFailedException.m	\
       OFConditionStillWaitingException.m	\
       OFConditionWaitFailedException.m		\
       OFConnectionFailedException.m		\
       OFCopyFileFailedException.m		\
       OFCreateDirectoryFailedException.m	\
       OFDeleteDirectoryFailedException.m	\
       OFDeleteFileFailedException.m		\
       OFEnumerationMutationException.m		\
       OFException.m				\
       OFHTTPRequestFailedException.m		\
       OFHashAlreadyCalculatedException.m	\
       OFInitializationFailedException.m	\
       OFInvalidArgumentException.m		\
       OFInvalidEncodingException.m		\
       OFInvalidFormatException.m		\
       OFInvalidJSONException.m			\
       OFInvalidServerReplyException.m		\
       OFLinkFailedException.m			\
       OFListenFailedException.m		\
       OFMalformedXMLException.m		\
       OFMemoryNotPartOfObjectException.m	\
       OFMutexLockFailedException.m		\
       OFMutexStillLockedException.m		\
       OFMutexUnlockFailedException.m		\
       OFNotConnectedException.m		\
       OFNotImplementedException.m		\
       OFOpenFileFailedException.m		\
       OFOutOfMemoryException.m			\
       OFOutOfRangeException.m			\
       OFReadFailedException.m			\
       OFReadOrWriteFailedException.m		\
       OFRenameFileFailedException.m		\
       OFSeekFailedException.m			\
       OFSetOptionFailedException.m		\
       OFSymlinkFailedException.m		\
       OFThreadJoinFailedException.m		\
       OFThreadStartFailedException.m		\
       OFThreadStillRunningException.m		\
       OFTruncatedDataException.m		\
       OFUnboundNamespaceException.m		\
       OFUnsupportedProtocolException.m		\
       OFWriteFailedException.m

INCLUDES = ${SRCS:.m=.h}

include ../../buildsys.mk

CPPFLAGS += -I. -I.. -I../..
LD = ${OBJC}
