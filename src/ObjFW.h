/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#import "OFObject.h"
#import "OFBlock.h"

#import "OFString.h"
#import "OFCharacterSet.h"

#import "OFData.h"
#import "OFArray.h"
#import "OFSecureData.h"

#import "OFList.h"
#import "OFSortedList.h"

#import "OFDictionary.h"
#import "OFMapTable.h"

#import "OFSet.h"
#import "OFCountedSet.h"

#import "OFValue.h"
#import "OFPair.h"
#import "OFTriple.h"

#import "OFEnumerator.h"

#import "OFNull.h"

#import "OFMethodSignature.h"
#import "OFInvocation.h"

#import "OFNumber.h"
#import "OFDate.h"
#import "OFUUID.h"
#import "OFURI.h"
#import "OFURIHandler.h"
#import "OFColor.h"

#import "OFNotification.h"
#import "OFNotificationCenter.h"

#import "OFStream.h"
#import "OFSeekableStream.h"
#import "OFMemoryStream.h"
#import "OFStdIOStream.h"
#import "OFInflateStream.h"
#import "OFInflate64Stream.h"
#import "OFGZIPStream.h"
#import "OFLHAArchive.h"
#import "OFLHAArchiveEntry.h"
#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"
#import "OFFileManager.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFINIFile.h"
#import "OFSettings.h"
#ifdef OF_HAVE_SOCKETS
# import "OFStreamSocket.h"
# import "OFDatagramSocket.h"
# import "OFSequencedPacketSocket.h"
# import "OFTCPSocket.h"
# import "OFUDPSocket.h"
# import "OFTLSStream.h"
# import "OFKernelEventObserver.h"
# import "OFDNSQuery.h"
# import "OFDNSResourceRecord.h"
# import "OFDNSResponse.h"
# import "OFDNSResolver.h"
# ifdef OF_HAVE_IPX
#  import "OFIPXSocket.h"
#  import "OFSPXSocket.h"
#  import "OFSPXStreamSocket.h"
# endif
# ifdef OF_HAVE_UNIX_SOCKETS
#  import "OFUNIXDatagramSocket.h"
#  import "OFUNIXStreamSocket.h"
# endif
#endif
#ifdef OF_HAVE_SOCKETS
# ifdef OF_HAVE_THREADS
#  import "OFHTTPClient.h"
# endif
# import "OFHTTPCookie.h"
# import "OFHTTPCookieManager.h"
# import "OFHTTPRequest.h"
# import "OFHTTPResponse.h"
# import "OFHTTPServer.h"
#endif

#ifdef OF_HAVE_SUBPROCESSES
# import "OFSubprocess.h"
#endif

#import "OFCryptographicHash.h"
#import "OFMD5Hash.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"

#import "OFHMAC.h"

#import "OFXMLAttribute.h"
#import "OFXMLElement.h"
#import "OFXMLAttribute.h"
#import "OFXMLCharacters.h"
#import "OFXMLCDATA.h"
#import "OFXMLComment.h"
#import "OFXMLProcessingInstruction.h"
#import "OFXMLParser.h"
#import "OFXMLElementBuilder.h"

#import "OFMessagePackExtension.h"

#import "OFApplication.h"
#import "OFSystemInfo.h"
#import "OFLocale.h"
#import "OFOptionsParser.h"
#import "OFTimer.h"
#import "OFRunLoop.h"

#ifdef OF_WINDOWS
# import "OFWindowsRegistryKey.h"
#endif

#import "OFAllocFailedException.h"
#import "OFException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFAcceptSocketFailedException.h"
# import "OFAlreadyConnectedException.h"
# import "OFBindSocketFailedException.h"
# import "OFBindIPSocketFailedException.h"
# ifdef OF_HAVE_UNIX_SOCKETS
#  import "OFBindUNIXSocketFailedException.h"
# endif
# ifdef OF_HAVE_IPX
#  import "OFBindIPXSocketFailedException.h"
# endif
#endif
#import "OFChangeCurrentDirectoryFailedException.h"
#import "OFChecksumMismatchException.h"
#ifdef OF_HAVE_THREADS
# import "OFConditionBroadcastFailedException.h"
# import "OFConditionSignalFailedException.h"
# import "OFConditionStillWaitingException.h"
# import "OFConditionWaitFailedException.h"
#endif
#ifdef OF_HAVE_SOCKETS
# import "OFConnectSocketFailedException.h"
# import "OFConnectIPSocketFailedException.h"
# ifdef OF_HAVE_UNIX_SOCKETS
#  import "OFConnectUNIXSocketFailedException.h"
# endif
# ifdef OF_HAVE_IPX
#  import "OFConnectSPXSocketFailedException.h"
# endif
#endif
#import "OFCopyItemFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#ifdef OF_WINDOWS
# import "OFCreateWindowsRegistryKeyFailedException.h"
#endif
#ifdef OF_HAVE_SOCKETS
# import "OFDNSQueryFailedException.h"
#endif
#ifdef OF_WINDOWS
# import "OFDeleteWindowsRegistryKeyFailedException.h"
# import "OFDeleteWindowsRegistryValueFailedException.h"
#endif
#import "OFEnumerationMutationException.h"
#ifdef OF_HAVE_FILES
# import "OFGetCurrentDirectoryFailedException.h"
#endif
#import "OFGetItemAttributesFailedException.h"
#import "OFGetOptionFailedException.h"
#ifdef OF_WINDOWS
# import "OFGetWindowsRegistryValueFailedException.h"
#endif
#import "OFHashAlreadyCalculatedException.h"
#import "OFHashNotCalculatedException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFHTTPRequestFailedException.h"
#endif
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidJSONException.h"
#import "OFInvalidServerResponseException.h"
#import "OFLinkItemFailedException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFListenFailedException.h"
#endif
#ifdef OF_HAVE_PLUGINS
# import "OFLoadPluginFailedException.h"
#endif
#import "OFLockFailedException.h"
#import "OFMalformedXMLException.h"
#import "OFMoveItemFailedException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFObserveKernelEventsFailedException.h"
#endif
#import "OFOpenItemFailedException.h"
#ifdef OF_WINDOWS
# import "OFOpenWindowsRegistryKeyFailedException.h"
#endif
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFReadOrWriteFailedException.h"
#import "OFRemoveItemFailedException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFResolveHostFailedException.h"
#endif
#import "OFSeekFailedException.h"
#import "OFSetItemAttributesFailedException.h"
#import "OFSetOptionFailedException.h"
#ifdef OF_WINDOWS
# import "OFSetWindowsRegistryValueFailedException.h"
#endif
#import "OFStillLockedException.h"
#ifdef OF_HAVE_THREADS
# import "OFThreadJoinFailedException.h"
# import "OFThreadStartFailedException.h"
# import "OFThreadStillRunningException.h"
#endif
#ifdef OF_HAVE_SOCKETS
# import "OFTLSHandshakeFailedException.h"
#endif
#import "OFTruncatedDataException.h"
#import "OFUnboundNamespaceException.h"
#import "OFUnboundPrefixException.h"
#import "OFUndefinedKeyException.h"
#import "OFUnknownXMLEntityException.h"
#import "OFUnlockFailedException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFUnsupportedVersionException.h"
#import "OFWriteFailedException.h"

#ifdef OF_HAVE_PLUGINS
# import "OFPlugin.h"
#endif

#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif
#import "OFLocking.h"
#import "OFOnce.h"
#import "OFThread.h"
#ifdef OF_HAVE_THREADS
# import "OFCondition.h"
# import "OFMutex.h"
# import "OFPlainCondition.h"
# import "OFPlainMutex.h"
# import "OFPlainThread.h"
# import "OFRecursiveMutex.h"
# import "OFTLSKey.h"
#endif

#import "OFPBKDF2.h"
#import "OFScrypt.h"
