/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include <errno.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include <signal.h>

#import "OFFileManager.h"
#import "OFRunLoop.h"

#import "macros.h"
#import "amiga-library.h"

#include <proto/exec.h>
#include <proto/intuition.h>

struct ObjFWBase;

#if defined(OF_AMIGAOS_M68K)
# include <stabs.h>
#elif defined(OF_MORPHOS)
# include <constructor.h>
#endif

#ifdef HAVE_SJLJ_EXCEPTIONS
extern int _Unwind_SjLj_RaiseException(void *);
#else
extern int _Unwind_RaiseException(void *);
#endif
extern void _Unwind_DeleteException(void *);
extern void *_Unwind_GetLanguageSpecificData(void *);
extern uintptr_t _Unwind_GetRegionStart(void *);
extern uintptr_t _Unwind_GetDataRelBase(void *);
extern uintptr_t _Unwind_GetTextRelBase(void *);
extern uintptr_t _Unwind_GetIP(void *);
extern uintptr_t _Unwind_GetGR(void *, int);
extern void _Unwind_SetIP(void *, uintptr_t);
extern void _Unwind_SetGR(void *, int, uintptr_t);
#ifdef HAVE_SJLJ_EXCEPTIONS
extern void _Unwind_SjLj_Resume(void *);
#else
extern void _Unwind_Resume(void *);
#endif
#ifdef OF_AMIGAOS_M68K
extern void __register_frame_info(const void *, void *);
extern void *__deregister_frame_info(const void *);
#endif
#ifdef OF_MORPHOS
extern void __register_frame(void *);
extern void __deregister_frame(void *);
#endif
extern int _Unwind_Backtrace(int (*)(void *, void *), void *);

struct Library *ObjFWBase;
void *__objc_class_name_OFASN1BitString;
void *__objc_class_name_OFASN1Boolean;
void *__objc_class_name_OFASN1Enumerated;
void *__objc_class_name_OFASN1IA5String;
void *__objc_class_name_OFASN1Integer;
void *__objc_class_name_OFASN1NumericString;
void *__objc_class_name_OFASN1ObjectIdentifier;
void *__objc_class_name_OFASN1OctetString;
void *__objc_class_name_OFASN1PrintableString;
void *__objc_class_name_OFASN1UTF8String;
void *__objc_class_name_OFASN1Value;
void *__objc_class_name_OFApplication;
void *__objc_class_name_OFArray;
void *__objc_class_name_OFCharacterSet;
void *__objc_class_name_OFColor;
void *__objc_class_name_OFConstantString;
void *__objc_class_name_OFCountedSet;
void *__objc_class_name_OFData;
void *__objc_class_name_OFDate;
void *__objc_class_name_OFDictionary;
void *__objc_class_name_OFEnumerator;
void *__objc_class_name_OFFileManager;
void *__objc_class_name_OFGZIPStream;
void *__objc_class_name_OFHMAC;
void *__objc_class_name_OFInflate64Stream;
void *__objc_class_name_OFInflateStream;
void *__objc_class_name_OFInvocation;
void *__objc_class_name_OFLHAArchive;
void *__objc_class_name_OFLHAArchiveEntry;
void *__objc_class_name_OFList;
void *__objc_class_name_OFLocale;
void *__objc_class_name_OFMapTable;
void *__objc_class_name_OFMapTableEnumerator;
void *__objc_class_name_OFMD5Hash;
void *__objc_class_name_OFMessagePackExtension;
void *__objc_class_name_OFMethodSignature;
void *__objc_class_name_OFMutableArray;
void *__objc_class_name_OFMutableData;
void *__objc_class_name_OFMutableDictionary;
void *__objc_class_name_OFMutableLHAArchiveEntry;
void *__objc_class_name_OFMutablePair;
void *__objc_class_name_OFMutableSet;
void *__objc_class_name_OFMutableString;
void *__objc_class_name_OFMutableTarArchiveEntry;
void *__objc_class_name_OFMutableTriple;
void *__objc_class_name_OFMutableURL;
void *__objc_class_name_OFMutableZIPArchiveEntry;
void *__objc_class_name_OFNull;
void *__objc_class_name_OFNumber;
void *__objc_class_name_OFObject;
void *__objc_class_name_OFOptionsParser;
void *__objc_class_name_OFPair;
void *__objc_class_name_OFRIPEMD160Hash;
void *__objc_class_name_OFRunLoop;
void *__objc_class_name_OFSandbox;
void *__objc_class_name_OFSecureData;
void *__objc_class_name_OFSeekableStream;
void *__objc_class_name_OFSet;
void *__objc_class_name_OFSHA1Hash;
void *__objc_class_name_OFSHA224Hash;
void *__objc_class_name_OFSHA224Or256Hash;
void *__objc_class_name_OFSHA256Hash;
void *__objc_class_name_OFSHA384Hash;
void *__objc_class_name_OFSHA384Or512Hash;
void *__objc_class_name_OFSHA512Hash;
void *__objc_class_name_OFSortedList;
void *__objc_class_name_OFStdIOStream;
void *__objc_class_name_OFStream;
void *__objc_class_name_OFString;
void *__objc_class_name_OFSystemInfo;
void *__objc_class_name_OFTarArchive;
void *__objc_class_name_OFTarArchiveEntry;
void *__objc_class_name_OFThread;
void *__objc_class_name_OFTimer;
void *__objc_class_name_OFTriple;
void *__objc_class_name_OFURL;
void *__objc_class_name_OFURLHandler;
void *__objc_class_name_OFValue;
void *__objc_class_name_OFXMLAttribute;
void *__objc_class_name_OFXMLCDATA;
void *__objc_class_name_OFXMLCharacters;
void *__objc_class_name_OFXMLComment;
void *__objc_class_name_OFXMLElement;
void *__objc_class_name_OFXMLElementBuilder;
void *__objc_class_name_OFXMLNode;
void *__objc_class_name_OFXMLParser;
void *__objc_class_name_OFXMLProcessingInstructions;
void *__objc_class_name_OFZIPArchive;
void *__objc_class_name_OFZIPArchiveEntry;
#ifdef OF_HAVE_FILES
void *__objc_class_name_OFFile;
void *__objc_class_name_OFINICategory;
void *__objc_class_name_OFINIFile;
void *__objc_class_name_OFSettings;
#endif
#ifdef OF_HAVE_SOCKETS
void *__objc_class_name_OFDNSQuery;
void *__objc_class_name_OFDNSResolver;
void *__objc_class_name_OFDNSResourceRecord;
void *__objc_class_name_OFADNSResourceRecord;
void *__objc_class_name_OFAAAADNSResourceRecord;
void *__objc_class_name_OFCNAMEDNSResourceRecord;
void *__objc_class_name_OFHINFODNSResourceRecord;
void *__objc_class_name_OFMXDNSResourceRecord;
void *__objc_class_name_OFNSDNSResourceRecord;
void *__objc_class_name_OFPTRDNSResourceRecord;
void *__objc_class_name_OFRPDNSResourceRecord;
void *__objc_class_name_OFSOADNSResourceRecord;
void *__objc_class_name_OFSRVDNSResourceRecord;
void *__objc_class_name_OFTXTDNSResourceRecord;
void *__objc_class_name_OFDNSResponse;
void *__objc_class_name_OFDatagramSocket;
void *__objc_class_name_OFHTTPClient;
void *__objc_class_name_OFHTTPCookie;
void *__objc_class_name_OFHTTPCookieManager;
void *__objc_class_name_OFHTTPRequest;
void *__objc_class_name_OFHTTPResponse;
void *__objc_class_name_OFHTTPServer;
void *__objc_class_name_OFSequencedPacketSocket;
void *__objc_class_name_OFStreamSocket;
void *__objc_class_name_OFTCPSocket;
void *__objc_class_name_OFUDPSocket;
void *__objc_class_name_OFKernelEventObserver;
#endif
#ifdef OF_HAVE_THREADS
void *__objc_class_name_OFCondition;
void *__objc_class_name_OFMutex;
void *__objc_class_name_OFRecursiveMutex;
void *__objc_class_name_OFThreadPool;
#endif
void *__objc_class_name_OFAllocFailedException;
void *__objc_class_name_OFChangeCurrentDirectoryPathFailedException;
void *__objc_class_name_OFChecksumMismatchException;
void *__objc_class_name_OFCopyItemFailedException;
void *__objc_class_name_OFCreateDirectoryFailedException;
void *__objc_class_name_OFCreateSymbolicLinkFailedException;
void *__objc_class_name_OFEnumerationMutationException;
void *__objc_class_name_OFException;
void *__objc_class_name_OFGetOptionFailedException;
void *__objc_class_name_OFHashAlreadyCalculatedException;
void *__objc_class_name_OFInitializationFailedException;
void *__objc_class_name_OFInvalidArgumentException;
void *__objc_class_name_OFInvalidEncodingException;
void *__objc_class_name_OFInvalidFormatException;
void *__objc_class_name_OFInvalidJSONException;
void *__objc_class_name_OFInvalidServerReplyException;
void *__objc_class_name_OFLinkFailedException;
void *__objc_class_name_OFLockFailedException;
void *__objc_class_name_OFMalformedXMLException;
void *__objc_class_name_OFMemoryNotPartOfObjectException;
void *__objc_class_name_OFMoveItemFailedException;
void *__objc_class_name_OFNotImplementedException;
void *__objc_class_name_OFNotOpenException;
void *__objc_class_name_OFOpenItemFailedException;
void *__objc_class_name_OFOutOfMemoryException;
void *__objc_class_name_OFOutOfRangeException;
void *__objc_class_name_OFReadFailedException;
void *__objc_class_name_OFReadOrWriteFailedException;
void *__objc_class_name_OFRemoveItemFailedException;
void *__objc_class_name_OFRetrieveItemAttributesFailedException;
void *__objc_class_name_OFSandboxActivationFailedException;
void *__objc_class_name_OFSeekFailedException;
void *__objc_class_name_OFSetItemAttributesFailedException;
void *__objc_class_name_OFSetOptionFailedException;
void *__objc_class_name_OFStillLockedException;
void *__objc_class_name_OFTruncatedDataException;
void *__objc_class_name_OFUnboundNamespaceException;
void *__objc_class_name_OFUnboundPrefixException;
void *__objc_class_name_OFUndefinedKeyException;
void *__objc_class_name_OFUnknownXMLEntityException;
void *__objc_class_name_OFUnlockFailedException;
void *__objc_class_name_OFUnsupportedProtocolException;
void *__objc_class_name_OFUnsupportedVersionException;
void *__objc_class_name_OFWriteFailedException;
#ifdef OF_HAVE_FILES
void *__objc_class_name_OFGetCurrentDirectoryPathFailedException;
#endif
#ifdef OF_HAVE_SOCKETS
void *__objc_class_name_OFAcceptFailedException;
void *__objc_class_name_OFAlreadyConnectedException;
void *__objc_class_name_OFBindFailedException;
void *__objc_class_name_OFConnectionFailedException;
void *__objc_class_name_OFDNSQueryFailedException;
void *__objc_class_name_OFHTTPRequestFailedException;
void *__objc_class_name_OFListenFailedException;
void *__objc_class_name_OFObserveFailedException;
void *__objc_class_name_OFResolveHostFailedException;
#endif
#ifdef OF_HAVE_THREADS
void *__objc_class_name_OFConditionBroadcastFailedException;
void *__objc_class_name_OFConditionSignalFailedException;
void *__objc_class_name_OFConditionStillWaitingException;
void *__objc_class_name_OFConditionWaitFailedException;
void *__objc_class_name_OFThreadJoinFailedException;
void *__objc_class_name_OFThreadStartFailedException;
void *__objc_class_name_OFThreadStillRunningException;
#endif
#include "OFFileManager_constants.m"
#include "OFRunLoop_constants.m"
/* The following __objc_class_name_* are only required for the tests. */
void *__objc_class_name_OFBitSetCharacterSet;
void *__objc_class_name_OFMapTableSet;
void *__objc_class_name_OFMutableMapTableSet;
void *__objc_class_name_OFMutableUTF8String;
void *__objc_class_name_OFRangeCharacterSet;
void *__objc_class_name_OFSelectKernelEventObserver;
void *__objc_class_name_OFUTF8String;

static void
error(const char *string, ULONG arg)
{
	struct Library *IntuitionBase = OpenLibrary("intuition.library", 0);

	if (IntuitionBase != NULL) {
		struct EasyStruct easy = {
			.es_StructSize = sizeof(easy),
			.es_Flags = 0,
			.es_Title = (UBYTE *)NULL,
			.es_TextFormat = (UBYTE *)string,
			(UBYTE *)"OK"
		};

		EasyRequest(NULL, &easy, NULL, arg);

		CloseLibrary(IntuitionBase);
	}

	exit(EXIT_FAILURE);
}

static int *
errNo(void)
{
	return &errno;
}

static void __attribute__((__used__))
ctor(void)
{
	static bool initialized = false;
	struct OFLibC libC = {
		.malloc = malloc,
		.calloc = calloc,
		.realloc = realloc,
		.free = free,
		.vfprintf = vfprintf,
		.fflush = fflush,
		.abort = abort,
#ifdef HAVE_SJLJ_EXCEPTIONS
		._Unwind_SjLj_RaiseException = _Unwind_SjLj_RaiseException,
#else
		._Unwind_RaiseException = _Unwind_RaiseException,
#endif
		._Unwind_DeleteException = _Unwind_DeleteException,
		._Unwind_GetLanguageSpecificData =
		    _Unwind_GetLanguageSpecificData,
		._Unwind_GetRegionStart = _Unwind_GetRegionStart,
		._Unwind_GetDataRelBase = _Unwind_GetDataRelBase,
		._Unwind_GetTextRelBase = _Unwind_GetTextRelBase,
		._Unwind_GetIP = _Unwind_GetIP,
		._Unwind_GetGR = _Unwind_GetGR,
		._Unwind_SetIP = _Unwind_SetIP,
		._Unwind_SetGR = _Unwind_SetGR,
#ifdef HAVE_SJLJ_EXCEPTIONS
		._Unwind_SjLj_Resume = _Unwind_SjLj_Resume,
#else
		._Unwind_Resume = _Unwind_Resume,
#endif
#ifdef OF_AMIGAOS_M68K
		.__register_frame_info = __register_frame_info,
		.__deregister_frame_info = __deregister_frame_info,
#endif
#ifdef OF_MORPHOS
		.__register_frame = __register_frame,
		.__deregister_frame = __deregister_frame,
#endif
		.errNo = errNo,
		.vsnprintf = vsnprintf,
#ifdef OF_AMIGAOS_M68K
		.vsscanf = vsscanf,
#endif
		.exit = exit,
		.atexit = atexit,
		.signal = signal,
		.setlocale = setlocale,
		._Unwind_Backtrace = _Unwind_Backtrace
	};

	if (initialized)
		return;

	if ((ObjFWBase = OpenLibrary(OBJFW_AMIGA_LIB, OBJFW_LIB_MINOR)) == NULL)
		error("Failed to open " OBJFW_AMIGA_LIB " version %lu!",
		    OBJFW_LIB_MINOR);

	if (!OFInit(1, &libC, __sF))
		error("Failed to initialize " OBJFW_AMIGA_LIB "!", 0);

	initialized = true;
}

static void __attribute__((__used__))
dtor(void)
{
	CloseLibrary(ObjFWBase);
}

#if defined(OF_AMIGAOS_M68K)
ADD2INIT(ctor, -2);
ADD2EXIT(dtor, -2);
#elif defined(OF_MORPHOS)
CONSTRUCTOR_P(ObjFW, 4000)
{
	ctor();

	return 0;
}

DESTRUCTOR_P(ObjFW, 4000)
{
	dtor();
}
#endif
