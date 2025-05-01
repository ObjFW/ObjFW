/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
#import "OFStdIOStream.h"

#import "macros.h"
#import "amiga-library.h"

#define USE_INLINE_STDARG
#include <proto/exec.h>
#include <proto/intuition.h>

#include <constructor.h>

extern struct Library *ObjFWRTBase;
extern int _Unwind_RaiseException(void *);
extern void _Unwind_DeleteException(void *);
extern void *_Unwind_GetLanguageSpecificData(void *);
extern uintptr_t _Unwind_GetRegionStart(void *);
extern uintptr_t _Unwind_GetDataRelBase(void *);
extern uintptr_t _Unwind_GetTextRelBase(void *);
extern uintptr_t _Unwind_GetIP(void *);
extern uintptr_t _Unwind_GetGR(void *, int);
extern void _Unwind_SetIP(void *, uintptr_t);
extern void _Unwind_SetGR(void *, int, uintptr_t);
extern void _Unwind_Resume(void *);
extern int _Unwind_Backtrace(int (*)(void *, void *), void *);
extern void __register_frame(void *);
extern void __deregister_frame(void *);

struct Library *ObjFWBase;
void *__objc_class_name_OFActivateSandboxFailedException;
void *__objc_class_name_OFAllocFailedException;
void *__objc_class_name_OFAlreadyOpenException;
void *__objc_class_name_OFApplication;
void *__objc_class_name_OFArray;
void *__objc_class_name_OFBlock;
void *__objc_class_name_OFCharacterSet;
void *__objc_class_name_OFChecksumMismatchException;
void *__objc_class_name_OFColor;
void *__objc_class_name_OFConstantString;
void *__objc_class_name_OFCopyItemFailedException;
void *__objc_class_name_OFCountedSet;
void *__objc_class_name_OFCreateDirectoryFailedException;
void *__objc_class_name_OFCreateSymbolicLinkFailedException;
void *__objc_class_name_OFData;
void *__objc_class_name_OFDate;
void *__objc_class_name_OFDictionary;
void *__objc_class_name_OFEnumerationMutationException;
void *__objc_class_name_OFEnumerator;
void *__objc_class_name_OFException;
void *__objc_class_name_OFFileManager;
void *__objc_class_name_OFGZIPStream;
void *__objc_class_name_OFGetItemAttributesFailedException;
void *__objc_class_name_OFGetOptionFailedException;
void *__objc_class_name_OFHMAC;
void *__objc_class_name_OFHashAlreadyCalculatedException;
void *__objc_class_name_OFHashNotCalculatedException;
void *__objc_class_name_OFINICategory;
void *__objc_class_name_OFINIFile;
void *__objc_class_name_OFINISection;
void *__objc_class_name_OFIRI;
void *__objc_class_name_OFIRIHandler;
void *__objc_class_name_OFInflate64Stream;
void *__objc_class_name_OFInflateStream;
void *__objc_class_name_OFInitializationFailedException;
void *__objc_class_name_OFInvalidArgumentException;
void *__objc_class_name_OFInvalidEncodingException;
void *__objc_class_name_OFInvalidFormatException;
void *__objc_class_name_OFInvalidJSONException;
void *__objc_class_name_OFInvalidServerResponseException;
void *__objc_class_name_OFInvocation;
void *__objc_class_name_OFLHAArchive;
void *__objc_class_name_OFLHAArchiveEntry;
void *__objc_class_name_OFLinkItemFailedException;
void *__objc_class_name_OFList;
void *__objc_class_name_OFLocale;
void *__objc_class_name_OFLockFailedException;
void *__objc_class_name_OFMD5Hash;
void *__objc_class_name_OFMalformedXMLException;
void *__objc_class_name_OFMapTable;
void *__objc_class_name_OFMatrix4x4;
void *__objc_class_name_OFMemoryStream;
void *__objc_class_name_OFMessagePackExtension;
void *__objc_class_name_OFMethodSignature;
void *__objc_class_name_OFMoveItemFailedException;
void *__objc_class_name_OFMutableArray;
void *__objc_class_name_OFMutableData;
void *__objc_class_name_OFMutableDictionary;
void *__objc_class_name_OFMutableIRI;
void *__objc_class_name_OFMutableLHAArchiveEntry;
void *__objc_class_name_OFMutablePair;
void *__objc_class_name_OFMutableSet;
void *__objc_class_name_OFMutableString;
void *__objc_class_name_OFMutableTarArchiveEntry;
void *__objc_class_name_OFMutableTriple;
void *__objc_class_name_OFMutableZIPArchiveEntry;
void *__objc_class_name_OFMutableZooArchiveEntry;
void *__objc_class_name_OFNotImplementedException;
void *__objc_class_name_OFNotOpenException;
void *__objc_class_name_OFNotification;
void *__objc_class_name_OFNotificationCenter;
void *__objc_class_name_OFNull;
void *__objc_class_name_OFNumber;
void *__objc_class_name_OFObject;
void *__objc_class_name_OFOpenItemFailedException;
void *__objc_class_name_OFOptionsParser;
void *__objc_class_name_OFOutOfMemoryException;
void *__objc_class_name_OFOutOfRangeException;
void *__objc_class_name_OFPair;
void *__objc_class_name_OFRIPEMD160Hash;
void *__objc_class_name_OFReadFailedException;
void *__objc_class_name_OFReadOrWriteFailedException;
void *__objc_class_name_OFRemoveItemFailedException;
void *__objc_class_name_OFRunLoop;
void *__objc_class_name_OFSHA1Hash;
void *__objc_class_name_OFSHA224Hash;
void *__objc_class_name_OFSHA224Or256Hash;
void *__objc_class_name_OFSHA256Hash;
void *__objc_class_name_OFSHA384Hash;
void *__objc_class_name_OFSHA384Or512Hash;
void *__objc_class_name_OFSHA512Hash;
void *__objc_class_name_OFSandbox;
void *__objc_class_name_OFSecureData;
void *__objc_class_name_OFSeekFailedException;
void *__objc_class_name_OFSeekableStream;
void *__objc_class_name_OFSet;
void *__objc_class_name_OFSetItemAttributesFailedException;
void *__objc_class_name_OFSetOptionFailedException;
void *__objc_class_name_OFSettings;
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
void *__objc_class_name_OFTruncatedDataException;
void *__objc_class_name_OFUUID;
void *__objc_class_name_OFUnboundNamespaceException;
void *__objc_class_name_OFUnboundPrefixException;
void *__objc_class_name_OFUndefinedKeyException;
void *__objc_class_name_OFUnknownXMLEntityException;
void *__objc_class_name_OFUnlockFailedException;
void *__objc_class_name_OFUnsupportedProtocolException;
void *__objc_class_name_OFUnsupportedVersionException;
void *__objc_class_name_OFValue;
void *__objc_class_name_OFWriteFailedException;
void *__objc_class_name_OFX509Certificate;
void *__objc_class_name_OFXMLAttribute;
void *__objc_class_name_OFXMLCDATA;
void *__objc_class_name_OFXMLCharacters;
void *__objc_class_name_OFXMLComment;
void *__objc_class_name_OFXMLElement;
void *__objc_class_name_OFXMLElementBuilder;
void *__objc_class_name_OFXMLNode;
void *__objc_class_name_OFXMLParser;
void *__objc_class_name_OFXMLProcessingInstruction;
void *__objc_class_name_OFZIPArchive;
void *__objc_class_name_OFZIPArchiveEntry;
void *__objc_class_name_OFZooArchive;
void *__objc_class_name_OFZooArchiveEntry;
#ifdef OF_HAVE_FILES
void *__objc_class_name_OFChangeCurrentDirectoryFailedException;
void *__objc_class_name_OFFile;
void *__objc_class_name_OFGetCurrentDirectoryFailedException;
#endif
#ifdef OF_HAVE_SOCKETS
void *__objc_class_name_OFAAAADNSResourceRecord;
void *__objc_class_name_OFADNSResourceRecord;
void *__objc_class_name_OFAcceptSocketFailedException;
void *__objc_class_name_OFBindIPSocketFailedException;
void *__objc_class_name_OFBindSocketFailedException;
void *__objc_class_name_OFCNAMEDNSResourceRecord;
void *__objc_class_name_OFConnectIPSocketFailedException;
void *__objc_class_name_OFConnectSocketFailedException;
void *__objc_class_name_OFDNSQuery;
void *__objc_class_name_OFDNSQueryFailedException;
void *__objc_class_name_OFDNSResolver;
void *__objc_class_name_OFDNSResourceRecord;
void *__objc_class_name_OFDNSResponse;
void *__objc_class_name_OFDatagramSocket;
void *__objc_class_name_OFHINFODNSResourceRecord;
void *__objc_class_name_OFHTTPClient;
void *__objc_class_name_OFHTTPCookie;
void *__objc_class_name_OFHTTPCookieManager;
void *__objc_class_name_OFHTTPRequest;
void *__objc_class_name_OFHTTPRequestFailedException;
void *__objc_class_name_OFHTTPResponse;
void *__objc_class_name_OFHTTPServer;
void *__objc_class_name_OFKernelEventObserver;
void *__objc_class_name_OFLOCDNSResourceRecord;
void *__objc_class_name_OFListenOnSocketFailedException;
void *__objc_class_name_OFMXDNSResourceRecord;
void *__objc_class_name_OFNSDNSResourceRecord;
void *__objc_class_name_OFPTRDNSResourceRecord;
void *__objc_class_name_OFRPDNSResourceRecord;
void *__objc_class_name_OFResolveHostFailedException;
void *__objc_class_name_OFSOADNSResourceRecord;
void *__objc_class_name_OFSRVDNSResourceRecord;
void *__objc_class_name_OFSequencedPacketSocket;
void *__objc_class_name_OFStreamSocket;
void *__objc_class_name_OFTCPSocket;
void *__objc_class_name_OFTLSHandshakeFailedException;
void *__objc_class_name_OFTLSStream;
void *__objc_class_name_OFTXTDNSResourceRecord;
void *__objc_class_name_OFUDPSocket;
void *__objc_class_name_OFURIDNSResourceRecord;
#endif
#ifdef OF_HAVE_THREADS
void *__objc_class_name_OFBroadcastConditionFailedException;
void *__objc_class_name_OFCondition;
void *__objc_class_name_OFConditionStillWaitingException;
void *__objc_class_name_OFJoinThreadFailedException;
void *__objc_class_name_OFMutex;
void *__objc_class_name_OFRecursiveMutex;
void *__objc_class_name_OFSignalConditionFailedException;
void *__objc_class_name_OFStartThreadFailedException;
void *__objc_class_name_OFStillLockedException;
void *__objc_class_name_OFThreadStillRunningException;
void *__objc_class_name_OFWaitForConditionFailedException;
#endif
/* Only used by tests. */
void *__objc_class_name_OFBitSetCharacterSet;
void *__objc_class_name_OFConcreteArray;
void *__objc_class_name_OFConcreteDictionary;
void *__objc_class_name_OFConcreteMutableArray;
void *__objc_class_name_OFConcreteMutableDictionary;
void *__objc_class_name_OFConcreteMutableSet;
void *__objc_class_name_OFConcreteSet;
void *__objc_class_name_OFMutableUTF8String;
void *__objc_class_name_OFRangeCharacterSet;
void *__objc_class_name_OFSelectKernelEventObserver;
void *__objc_class_name_OFUTF8String;

#include "OFFileManagerConstants.inc"
#include "OFRunLoopConstants.inc"
#ifdef OF_HAVE_SOCKETS
# include "OFSystemInfo+NetworkInterfacesConstants.inc"
#endif

#ifndef OF_AMIGA_LIB
struct Library *ObjFWBase;

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
errNoRef(void)
{
	return &errno;
}

static void __attribute__((__used__))
ctor(void)
{
	static bool initialized = false;
	struct OFLinklibContext ctx = {
		.version = 1,
		.ObjFWRTBase = ObjFWRTBase,
		.malloc = malloc,
		.calloc = calloc,
		.realloc = realloc,
		.free = free,
		._Unwind_RaiseException = _Unwind_RaiseException,
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
		._Unwind_Resume = _Unwind_Resume,
		._Unwind_Backtrace = _Unwind_Backtrace,
		.__register_frame = __register_frame,
		.__deregister_frame = __deregister_frame,
		.atexit = atexit,
		.exit = exit,
		.abort = abort,
		.errNoRef = errNoRef,
		.vasprintf = vasprintf,
		.strtof = strtof,
		.strtod = strtod,
		.gmtime_r = gmtime_r,
		.localtime_r = localtime_r,
		.mktime = mktime,
		.strftime = strftime,
		.signal = signal,
		.setlocale = setlocale,
		.setjmp = setjmp,
		.longjmp = longjmp,
	};

	if (initialized)
		return;

	if ((ObjFWBase = OpenLibrary(OBJFW_AMIGA_LIB, OBJFW_LIB_MINOR)) == NULL)
		error("Failed to open " OBJFW_AMIGA_LIB " version %lu!",
		    OBJFW_LIB_MINOR);

	if (!OFInit(&ctx))
		error("Failed to initialize " OBJFW_AMIGA_LIB "!", 0);

	initialized = true;
}

static void __attribute__((__used__))
dtor(void)
{
	if (ObjFWBase != NULL)
		CloseLibrary(ObjFWBase);
}

# if defined(OF_AMIGAOS_M68K)
ADD2INIT(ctor, -2);
ADD2EXIT(dtor, -2);
# elif defined(OF_MORPHOS)
CONSTRUCTOR_P(ObjFW, 5000)
{
	ctor();

	return 0;
}

DESTRUCTOR_P(ObjFW, 5000)
{
	dtor();
}
# endif
#endif

void
OFLog(OFConstantString *format, ...)
{
	va_list arguments;

	va_start(arguments, format);
	OFLogV(format, arguments);
	va_end(arguments);
}
