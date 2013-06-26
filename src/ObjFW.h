/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "objfw-defs.h"

#import "OFObject.h"
#import "OFBlock.h"

#import "OFAutoreleasePool.h"
#import "OFString.h"

#import "OFArray.h"
#import "OFDataArray.h"

#import "OFList.h"
#import "OFSortedList.h"

#import "OFDictionary.h"
#import "OFMapTable.h"

#import "OFSet.h"
#import "OFCountedSet.h"

#import "OFEnumerator.h"

#import "OFNull.h"

#import "OFIntrospection.h"

#import "OFNumber.h"
#import "OFDate.h"
#import "OFURL.h"

#import "OFStream.h"
#import "OFStdIOStream.h"
#import "OFFile.h"
#ifdef OF_HAVE_SOCKETS
# import "OFStreamSocket.h"
# import "OFTCPSocket.h"
# import "OFTLSSocket.h"
# import "OFStreamObserver.h"

# import "OFHTTPRequest.h"
# import "OFHTTPRequestReply.h"
# import "OFHTTPClient.h"
# import "OFHTTPServer.h"
#endif

#ifdef OF_HAVE_PROCESSES
# import "OFProcess.h"
#endif

#import "OFHash.h"
#import "OFMD5Hash.h"
#import "OFSHA1Hash.h"

#import "OFXMLAttribute.h"
#import "OFXMLElement.h"
#import "OFXMLAttribute.h"
#import "OFXMLCharacters.h"
#import "OFXMLCDATA.h"
#import "OFXMLComment.h"
#import "OFXMLProcessingInstructions.h"
#import "OFXMLParser.h"
#import "OFXMLElementBuilder.h"

#import "OFMessagePackExtension.h"

#import "OFApplication.h"
#import "OFSystemInfo.h"
#import "OFTimer.h"
#import "OFRunLoop.h"

#import "OFAllocFailedException.h"
#import "OFException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFAcceptFailedException.h"
# import "OFAddressTranslationFailedException.h"
# import "OFAlreadyConnectedException.h"
# import "OFBindFailedException.h"
#endif
#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFChangeOwnerFailedException.h"
#import "OFChangePermissionsFailedException.h"
#ifdef OF_HAVE_THREADS
# import "OFConditionBroadcastFailedException.h"
# import "OFConditionSignalFailedException.h"
# import "OFConditionStillWaitingException.h"
# import "OFConditionWaitFailedException.h"
#endif
#ifdef OF_HAVE_SOCKETS
# import "OFConnectionFailedException.h"
#endif
#import "OFCopyFileFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#import "OFEnumerationMutationException.h"
#import "OFHashAlreadyCalculatedException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFHTTPRequestFailedException.h"
#endif
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidJSONException.h"
#import "OFInvalidServerReplyException.h"
#import "OFLinkFailedException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFListenFailedException.h"
#endif
#import "OFLockFailedException.h"
#import "OFMalformedXMLException.h"
#import "OFMemoryNotPartOfObjectException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFNotConnectedException.h"
#endif
#import "OFNotImplementedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFReadOrWriteFailedException.h"
#import "OFRemoveFailedException.h"
#import "OFRenameFailedException.h"
#import "OFSeekFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFStillLockedException.h"
#ifdef OF_HAVE_THREADS
# import "OFThreadJoinFailedException.h"
# import "OFThreadStartFailedException.h"
# import "OFThreadStillRunningException.h"
#endif
#import "OFTruncatedDataException.h"
#import "OFUnboundNamespaceException.h"
#import "OFUnlockFailedException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFUnsupportedVersionException.h"
#import "OFWriteFailedException.h"

#import "macros.h"

#ifdef OF_HAVE_PLUGINS
# import "OFPlugin.h"
#endif

#ifdef OF_HAVE_ATOMIC_OPS
# import "atomic.h"
#endif

#import "OFLocking.h"
#import "OFThread.h"
#ifdef OF_HAVE_THREADS
# import "threading.h"
# import "OFThreadPool.h"
# import "OFTLSKey.h"
# import "OFMutex.h"
# import "OFRecursiveMutex.h"
# import "OFCondition.h"
#endif

#import "autorelease.h"
#import "asprintf.h"
#import "base64.h"
#import "of_asprintf.h"
#import "of_strptime.h"
