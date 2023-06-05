/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#define __NO_EXT_QNX

#include "config.h"

#include <limits.h>	/* include any libc header to get the libc defines */

#include "unistd_wrapper.h"

#include "platform.h"

#ifdef HAVE_SYS_UTSNAME_H
# include <sys/utsname.h>
#endif
#if defined(OF_MACOS) || defined(OF_IOS) || defined(OF_NETBSD)
# include <sys/sysctl.h>
#endif

#ifdef HAVE_NET_IF_H
# include <net/if.h>
#endif
#ifdef HAVE_NET_IF_TYPES_H
# include <net/if_types.h>
#endif
#ifdef HAVE_NET_IF_DL_H
# include <net/if_dl.h>
#endif
#ifdef HAVE_NETPACKET_PACKET_H
# include <netpacket/packet.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <exec/execbase.h>
# include <proto/exec.h>
# undef Class
#endif

#if defined(OF_AMIGAOS4)
# include <exec/exectags.h>
#elif defined(OF_MORPHOS)
# include <exec/system.h>
#endif

#ifdef OF_NINTENDO_SWITCH
# define id nx_id
# import <switch.h>
# undef nx_id
#endif

#ifdef OF_DJGPP
# include <dos.h>
#endif

#import "OFSystemInfo.h"
#import "OFApplication.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
 #import "OFFile.h"
#endif
#import "OFIRI.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFOnce.h"
#ifdef OF_HAVE_SOCKETS
# import "OFSocket.h"
# import "OFSocket+Private.h"
#endif
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

#if defined(OF_MACOS) || defined(OF_IOS)
# ifdef HAVE_SYSDIR_H
#  include <sysdir.h>
# endif
#endif
#ifdef OF_WINDOWS
# include <windows.h>
#endif
#ifdef OF_HAIKU
# include <FindDirectory.h>
#endif
#ifdef OF_QNX
# include <sys/syspage.h>
#endif

#if !defined(PATH_MAX) && defined(MAX_PATH)
# define PATH_MAX MAX_PATH
#endif

#if defined(OF_MACOS) || defined(OF_IOS)
/*
 * These have been dropped from newer iOS SDKs, however, their replacements are
 * not available on iOS < 10. This means it's impossible to search for the
 * paths when using a new SDK while targeting iOS 9 or earlier. To work around
 * this, we define those manually, only to be used when the replacements are
 * not available at runtime.
 */

typedef enum {
	NSLibraryDirectory = 5,
	NSApplicationSupportDirectory = 14
} NSSearchPathDirectory;

typedef enum {
	NSUserDomainMask = 1
} NSSearchPathDomainMask;

typedef unsigned int NSSearchPathEnumerationState;

extern NSSearchPathEnumerationState NSStartSearchPathEnumeration(
    NSSearchPathDirectory, NSSearchPathDomainMask);
extern NSSearchPathEnumerationState NSGetNextSearchPathEnumeration(
    NSSearchPathEnumerationState, char *);
#endif

#ifdef OF_HAVE_SOCKETS
OFNetworkInterfaceKey OFNetworkInterfaceIndex = @"OFNetworkInterfaceIndex";
OFNetworkInterfaceKey OFNetworkInterfaceIPv6Addresses =
    @"OFNetworkInterfaceIPv6Addresses";
OFNetworkInterfaceKey OFNetworkInterfaceIPv4Addresses =
    @"OFNetworkInterfaceIPv4Addresses";
#endif

#if defined(OF_AMD64) || defined(OF_X86)
struct X86Regs {
	uint32_t eax, ebx, ecx, edx;
};
#endif

static size_t pageSize = 4096;
static size_t numberOfCPUs = 1;
static OFString *operatingSystemName = nil;
static OFString *operatingSystemVersion = nil;

static void
initOperatingSystemName(void)
{
#if defined(OF_IOS)
	operatingSystemName = @"iOS";
#elif defined(OF_MACOS)
	operatingSystemName = @"macOS";
#elif defined(OF_WINDOWS)
	operatingSystemName = @"Windows";
#elif defined(OF_ANDROID)
	operatingSystemName = @"Android";
#elif defined(OF_AMIGAOS_M68K)
	operatingSystemName = @"AmigaOS";
#elif defined(OF_MORPHOS)
	operatingSystemName = @"MorphOS";
#elif defined(OF_AMIGAOS4)
	operatingSystemName = @"AmigaOS 4";
#elif defined(OF_WII)
	operatingSystemName = @"Nintendo Wii";
#elif defined(OF_WII_U)
	operatingSystemName = @"Nintendo Wii U";
#elif defined(NINTENDO_3DS)
	operatingSystemName = @"Nintendo 3DS";
#elif defined(OF_NINTENDO_DS)
	operatingSystemName = @"Nintendo DS";
#elif defined(OF_NINTENDO_SWITCH)
	operatingSystemName = @"Nintendo Switch";
#elif defined(OF_PSP)
	operatingSystemName = @"PlayStation Portable";
#elif defined(OF_DJGPP)
	operatingSystemName = [[OFString alloc]
	    initWithCString: _os_flavor
		   encoding: OFStringEncodingASCII];
#elif defined(HAVE_SYS_UTSNAME_H) && defined(HAVE_UNAME)
	struct utsname name;

	if (uname(&name) != 0)
		return;

	operatingSystemName = [[OFString alloc]
	    initWithCString: name.sysname
		   encoding: [OFLocale encoding]];
#endif
}

static void
initOperatingSystemVersion(void)
{
#if defined(OF_IOS) || defined(OF_MACOS)
# ifdef OF_HAVE_FILES
	void *pool = objc_autoreleasePoolPush();

	@try {
		OFDictionary *propertyList = [[OFString
		    stringWithContentsOfFile: @"/System/Library/CoreServices/"
		                              @"SystemVersion.plist"]
		    objectByParsingPropertyList];

		operatingSystemVersion = [[propertyList
		    objectForKey: @"ProductVersion"] copy];
	} @finally {
		objc_autoreleasePoolPop(pool);
	}
# endif
#elif defined(OF_WINDOWS)
# ifdef OF_HAVE_FILES
	void *pool = objc_autoreleasePoolPush();

	@try {
		OFStringEncoding encoding = [OFLocale encoding];
		char systemDir[PATH_MAX];
		UINT systemDirLen;
		OFString *systemDirString;
		const char *path;
		void *buffer;
		DWORD bufferLen;

		systemDirLen = GetSystemDirectoryA(systemDir, PATH_MAX);
		if (systemDirLen == 0)
			return;

		systemDirString = [OFString stringWithCString: systemDir
						     encoding: encoding
						       length: systemDirLen];
		path = [[systemDirString stringByAppendingPathComponent:
		    @"kernel32.dll"] cStringWithEncoding: encoding];

		if ((bufferLen = GetFileVersionInfoSizeA(path, NULL)) == 0)
			return;
		if ((buffer = malloc(bufferLen)) == 0)
			return;

		@try {
			void *data;
			UINT dataLen;
			VS_FIXEDFILEINFO *info;

			if (!GetFileVersionInfoA(path, 0, bufferLen, buffer))
				return;

			if (!VerQueryValueA(buffer, "\\", &data, &dataLen) ||
			    dataLen < sizeof(info))
				return;

			info = (VS_FIXEDFILEINFO *)data;

			operatingSystemVersion = [[OFString alloc]
			    initWithFormat: @"%u.%u.%u",
					    HIWORD(info->dwProductVersionMS),
					    LOWORD(info->dwProductVersionMS),
					    HIWORD(info->dwProductVersionLS)];
		} @finally {
			free(buffer);
		}
	} @finally {
		objc_autoreleasePoolPop(pool);
	}
# endif
#elif defined(OF_ANDROID)
	/* TODO */
#elif defined(OF_AMIGAOS)
	operatingSystemVersion = [[OFString alloc]
	    initWithFormat: @"Kickstart %u.%u",
			    SysBase->LibNode.lib_Version, SysBase->SoftVer];
#elif defined(OF_DJGPP)
	operatingSystemVersion = [[OFString alloc]
	    initWithFormat: @"%u.%u", _osmajor, _osminor];
#elif defined(OF_WII) || defined(NINTENDO_3DS) || defined(OF_NINTENDO_DS) || \
    defined(OF_PSP)
	/* Intentionally nothing */
#elif defined(HAVE_SYS_UTSNAME_H) && defined(HAVE_UNAME)
	struct utsname name;

	if (uname(&name) != 0)
		return;

	operatingSystemVersion = [[OFString alloc]
	    initWithCString: name.release
		   encoding: [OFLocale encoding]];
#endif
}

#ifdef OF_NINTENDO_SWITCH
static OFIRI *tmpFSIRI = nil;

static void
mountTmpFS(void)
{
	if (R_SUCCEEDED(fsdevMountTemporaryStorage("tmpfs")))
		tmpFSIRI = [[OFIRI alloc] initFileIRIWithPath: @"tmpfs:/"
						  isDirectory: true];
}
#endif

#if defined(OF_AMD64) || defined(OF_X86)
static OF_INLINE struct X86Regs OF_CONST_FUNC
x86CPUID(uint32_t eax, uint32_t ecx)
{
	struct X86Regs regs;

# if defined(OF_AMD64) && defined(__GNUC__)
	__asm__ (
	    "cpuid"
	    : "=a"(regs.eax), "=b"(regs.ebx), "=c"(regs.ecx), "=d"(regs.edx)
	    : "a"(eax), "c"(ecx)
	);
# elif defined(OF_X86) && defined(__GNUC__)
	/*
	 * This workaround is required by older GCC versions when using -fPIC,
	 * as ebx is a special register in PIC code. Yes, GCC is indeed not
	 * able to just push a register onto the stack before the __asm__ block
	 * and to pop it afterwards.
	 */
	__asm__ (
	    "xchgl	%%ebx, %%edi\n\t"
	    "cpuid\n\t"
	    "xchgl	%%edi, %%ebx"
	    : "=a"(regs.eax), "=D"(regs.ebx), "=c"(regs.ecx), "=d"(regs.edx)
	    : "a"(eax), "c"(ecx)
	);
# else
	memset(&regs, 0, sizeof(regs));
# endif

	return regs;
}
#endif

@implementation OFSystemInfo
+ (void)initialize
{
	long tmp;

	if (self != [OFSystemInfo class])
		return;

#if defined(OF_WINDOWS)
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	pageSize = si.dwPageSize;
	numberOfCPUs = si.dwNumberOfProcessors;
#elif defined(OF_QNX)
	if ((tmp = sysconf(_SC_PAGESIZE)) > 0)
		pageSize = tmp;
	numberOfCPUs = _syspage_ptr->num_cpu;
#else
# if defined(HAVE_SYSCONF) && defined(_SC_PAGESIZE)
	if ((tmp = sysconf(_SC_PAGESIZE)) > 0)
		pageSize = tmp;
# endif
# if defined(HAVE_SYSCONF) && defined(_SC_NPROCESSORS_CONF)
	if ((tmp = sysconf(_SC_NPROCESSORS_CONF)) > 0)
		numberOfCPUs = tmp;
# endif
#endif

	(void)tmp;
}

+ (instancetype)alloc
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (size_t)pageSize
{
	return pageSize;
}

+ (size_t)numberOfCPUs
{
	return numberOfCPUs;
}

+ (OFString *)ObjFWVersion
{
	return @PACKAGE_VERSION;
}

+ (unsigned short)ObjFWVersionMajor
{
	return OBJFW_VERSION_MAJOR;
}

+ (unsigned short)ObjFWVersionMinor
{
	return OBJFW_VERSION_MINOR;
}

+ (OFString *)operatingSystemName
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initOperatingSystemName);

	return operatingSystemName;
}

+ (OFString *)operatingSystemVersion
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initOperatingSystemVersion);

	return operatingSystemVersion;
}

+ (OFIRI *)userDataIRI
{
#ifdef OF_HAVE_FILES
# if defined(OF_MACOS) || defined(OF_IOS)
	char pathC[PATH_MAX];
	OFMutableString *path;

#  ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	if (@available(macOS 10.12, iOS 10, *)) {
		sysdir_search_path_enumeration_state state;

		state = sysdir_start_search_path_enumeration(
		    SYSDIR_DIRECTORY_APPLICATION_SUPPORT,
		    SYSDIR_DOMAIN_MASK_USER);
		if (sysdir_get_next_search_path_enumeration(state, pathC) == 0)
			return nil;
	} else {
#  endif
		NSSearchPathEnumerationState state;

		state = NSStartSearchPathEnumeration(
		    NSApplicationSupportDirectory, NSUserDomainMask);
		if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
			return nil;
#  ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	}
#  endif

	path = [OFMutableString stringWithUTF8String: pathC];
	if ([path hasPrefix: @"~"]) {
		OFDictionary *env = [OFApplication environment];
		OFString *home;

		if ((home = [env objectForKey: @"HOME"]) == nil)
			return nil;

		[path deleteCharactersInRange: OFMakeRange(0, 1)];
		[path insertString: home atIndex: 0];
	}

	[path makeImmutable];

	return [OFIRI fileIRIWithPath: path isDirectory: true];
# elif defined(OF_WINDOWS)
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		return nil;

	return [OFIRI fileIRIWithPath: appData isDirectory: true];
# elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		return nil;

	return [OFIRI fileIRIWithPath: [OFString stringWithUTF8String: pathC]
			  isDirectory: true];
# elif defined(OF_AMIGAOS)
	return [OFIRI fileIRIWithPath: @"PROGDIR:" isDirectory: true];
# else
	OFDictionary *env = [OFApplication environment];
	OFString *var;
	OFIRI *IRI;
	void *pool;

	if ((var = [env objectForKey: @"XDG_DATA_HOME"]) != nil &&
	    var.length > 0)
		return [OFIRI fileIRIWithPath: var isDirectory: true];

	if ((var = [env objectForKey: @"HOME"]) == nil)
		return nil;

	pool = objc_autoreleasePoolPush();

	var = [OFString pathWithComponents: [OFArray arrayWithObjects:
	    var, @".local", @"share", nil]];
	IRI = [[OFIRI alloc] initFileIRIWithPath: var isDirectory: true];

	objc_autoreleasePoolPop(pool);

	return [IRI autorelease];
# endif
#else
	return nil;
#endif
}

+ (OFIRI *)userConfigIRI
{
#ifdef OF_HAVE_FILES
# if defined(OF_MACOS) || defined(OF_IOS)
	char pathC[PATH_MAX];
	OFMutableString *path;

#  ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	if (@available(macOS 10.12, iOS 10, *)) {
		sysdir_search_path_enumeration_state state;

		state = sysdir_start_search_path_enumeration(
		    SYSDIR_DIRECTORY_LIBRARY, SYSDIR_DOMAIN_MASK_USER);
		if (sysdir_get_next_search_path_enumeration(state, pathC) == 0)
			return nil;
	} else {
#  endif
		NSSearchPathEnumerationState state;

		state = NSStartSearchPathEnumeration(NSLibraryDirectory,
		    NSUserDomainMask);
		if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
			return nil;
#  ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	}
#  endif

	path = [OFMutableString stringWithUTF8String: pathC];
	if ([path hasPrefix: @"~"]) {
		OFDictionary *env = [OFApplication environment];
		OFString *home;

		if ((home = [env objectForKey: @"HOME"]) == nil)
			return nil;

		[path deleteCharactersInRange: OFMakeRange(0, 1)];
		[path insertString: home atIndex: 0];
	}

	[path appendString: @"/Preferences"];
	[path makeImmutable];

	return [OFIRI fileIRIWithPath: path isDirectory: true];
# elif defined(OF_WINDOWS)
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		return nil;

	return [OFIRI fileIRIWithPath: appData isDirectory: true];
# elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		return nil;

	return [OFIRI fileIRIWithPath: [OFString stringWithUTF8String: pathC]
			  isDirectory: true];
# elif defined(OF_AMIGAOS)
	return [OFIRI fileIRIWithPath: @"PROGDIR:" isDirectory: true];
# else
	OFDictionary *env = [OFApplication environment];
	OFString *var;

	if ((var = [env objectForKey: @"XDG_CONFIG_HOME"]) != nil &&
	    var.length > 0)
		return [OFIRI fileIRIWithPath: var isDirectory: true];

	if ((var = [env objectForKey: @"HOME"]) == nil)
		return nil;

	var = [var stringByAppendingPathComponent: @".config"];

	return [OFIRI fileIRIWithPath: var isDirectory: true];
# endif
#else
	return nil;
#endif
}

+ (OFIRI *)temporaryDirectoryIRI
{
#ifdef OF_HAVE_FILES
# if defined(OF_MACOS) || defined(OF_IOS)
	char buffer[PATH_MAX];
	size_t length;
	OFString *path;

	if ((length = confstr(_CS_DARWIN_USER_TEMP_DIR, buffer, PATH_MAX)) == 0)
		return [OFIRI fileIRIWithPath: @"/tmp" isDirectory: true];

	path = [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]
				    length: length - 1];

	return [OFIRI fileIRIWithPath: path isDirectory: true];
# elif defined(OF_WINDOWS)
	OFString *path;

	if ([self isWindowsNT]) {
		wchar_t buffer[PATH_MAX];

		if (!GetTempPathW(PATH_MAX, buffer))
			return nil;

		path = [OFString stringWithUTF16String: buffer];
	} else {
		char buffer[PATH_MAX];

		if (!GetTempPathA(PATH_MAX, buffer))
			return nil;

		path = [OFString stringWithCString: buffer
					  encoding: [OFLocale encoding]];
	}

	return [OFIRI fileIRIWithPath: path isDirectory: true];
# elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_SYSTEM_TEMP_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		return nil;

	return [OFIRI fileIRIWithPath: [OFString stringWithUTF8String: pathC]
			  isDirectory: true];
# elif defined(OF_AMIGAOS)
	return [OFIRI fileIRIWithPath: @"T:" isDirectory: true];
# elif defined(OF_MSDOS)
	OFString *path = [[OFApplication environment] objectForKey: @"TEMP"];

	if (path == nil)
		return nil;

	return [OFIRI fileIRIWithPath: path isDirectory: true];
# elif defined(OF_MINT)
	return [OFIRI fileIRIWithPath: @"u:\\tmp" isDirectory: true];
# elif defined(OF_NINTENDO_SWITCH)
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, mountTmpFS);

	return tmpFSIRI;
# else
	OFString *path;

	path = [[OFApplication environment] objectForKey: @"XDG_RUNTIME_DIR"];
	if (path != nil)
		return [OFIRI fileIRIWithPath: path isDirectory: true];

	path = [[OFApplication environment] objectForKey: @"TMPDIR"];
	if (path != nil)
		return [OFIRI fileIRIWithPath: path isDirectory: true];

	return [OFIRI fileIRIWithPath: @"/tmp" isDirectory: true];
# endif
#else
	return nil;
#endif
}

+ (OFString *)CPUVendor
{
#if (defined(OF_AMD64) || defined(OF_X86)) && defined(__GNUC__)
	struct X86Regs regs = x86CPUID(0, 0);
	uint32_t buffer[3];

	if (regs.eax == 0)
		return nil;

	buffer[0] = regs.ebx;
	buffer[1] = regs.edx;
	buffer[2] = regs.ecx;

	return [OFString stringWithCString: (char *)buffer
				  encoding: OFStringEncodingASCII
				    length: 12];
#elif defined(OF_M68K)
	return @"Motorola";
#else
	return nil;
#endif
}

+ (OFString *)CPUModel
{
#if (defined(OF_AMD64) || defined(OF_X86)) && defined(__GNUC__)
	struct X86Regs regs = x86CPUID(0x80000000, 0);
	uint32_t buffer[12];
	size_t i;

	if (regs.eax < 0x80000004)
		return nil;

	i = 0;
	for (uint32_t eax = 0x80000002; eax <= 0x80000004; eax++) {
		regs = x86CPUID(eax, 0);
		buffer[i++] = regs.eax;
		buffer[i++] = regs.ebx;
		buffer[i++] = regs.ecx;
		buffer[i++] = regs.edx;
	}

	return [OFString stringWithCString: (char *)buffer
				  encoding: OFStringEncodingASCII];
#elif defined(OF_MACOS) || defined(OF_IOS)
	char buffer[128];
	size_t length = sizeof(buffer);

	if (sysctlbyname("machdep.cpu.brand_string", &buffer, &length,
	    NULL, 0) != 0)
		return nil;

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]
				    length: length];
#elif defined(OF_AMIGAOS4)
	CONST_STRPTR model, version;

	GetCPUInfoTags(GCIT_ModelString, &model,
	    GCIT_VersionString, &version, TAG_END);

	if (version != NULL)
		return [OFString stringWithFormat: @"%s V%s", model, version];
	else
		return [OFString stringWithCString: model
					  encoding: OFStringEncodingASCII];
#elif defined(OF_AMIGAOS_M68K)
	if (SysBase->AttnFlags & AFF_68060)
		return @"68060";
	if (SysBase->AttnFlags & AFF_68040)
		return @"68040";
	if (SysBase->AttnFlags & AFF_68030)
		return @"68030";
	if (SysBase->AttnFlags & AFF_68020)
		return @"68020";
	if (SysBase->AttnFlags & AFF_68010)
		return @"68010";
	else
		return @"68000";
#else
	return nil;
#endif
}

#if defined(OF_AMD64) || defined(OF_X86)
+ (bool)supportsMMX
{
	return (x86CPUID(1, 0).edx & (1u << 23));
}

+ (bool)supports3DNow
{
	return (x86CPUID(0x80000001, 0).edx & (1u << 31));
}

+ (bool)supportsEnhanced3DNow
{
	return (x86CPUID(0x80000001, 0).edx & (1u << 30));
}

+ (bool)supportsSSE
{
	return (x86CPUID(1, 0).edx & (1u << 25));
}

+ (bool)supportsSSE2
{
	return (x86CPUID(1, 0).edx & (1u << 26));
}

+ (bool)supportsSSE3
{
	return (x86CPUID(1, 0).ecx & (1u << 0));
}

+ (bool)supportsSSSE3
{
	return (x86CPUID(1, 0).ecx & (1u << 9));
}

+ (bool)supportsSSE41
{
	return (x86CPUID(1, 0).ecx & (1u << 19));
}

+ (bool)supportsSSE42
{
	return (x86CPUID(1, 0).ecx & (1u << 20));
}

+ (bool)supportsAVX
{
	return (x86CPUID(1, 0).ecx & (1u << 28));
}

+ (bool)supportsAVX2
{
	return x86CPUID(0, 0).eax >= 7 && (x86CPUID(7, 0).ebx & (1u << 5));
}

+ (bool)supportsAESNI
{
	return (x86CPUID(1, 0).ecx & (1u << 25));
}

+ (bool)supportsSHAExtensions
{
	return (x86CPUID(7, 0).ebx & (1u << 29));
}
#endif

#if defined(OF_POWERPC) || defined(OF_POWERPC64)
+ (bool)supportsAltiVec
{
# if defined(OF_MACOS)
	int name[2] = { CTL_HW, HW_VECTORUNIT }, value = 0;
	size_t length = sizeof(value);

	if (sysctl(name, 2, &value, &length, NULL, 0) == 0)
		return value;
# elif defined(OF_AMIGAOS4)
	uint32_t vectorUnit;

	GetCPUInfoTags(GCIT_VectorUnit, &vectorUnit, TAG_END);

	return (vectorUnit == VECTORTYPE_ALTIVEC);
# elif defined(OF_MORPHOS)
	uint32_t supportsAltiVec;

	if (NewGetSystemAttrs(&supportsAltiVec, sizeof(supportsAltiVec),
	    SYSTEMINFOTYPE_PPC_ALTIVEC, TAG_DONE) > 0)
		return supportsAltiVec;
# endif

	return false;
}
#endif

#ifdef OF_WINDOWS
+ (bool)isWindowsNT
{
	return !(GetVersion() & 0x80000000);
}
#endif

#ifdef OF_HAVE_SOCKETS
static bool
queryNetworkInterfaceIndices(OFMutableDictionary *ret)
{
# ifdef HAVE_IF_NAMEINDEX
	OFStringEncoding encoding = [OFLocale encoding];
	struct if_nameindex *nameindex = if_nameindex();

	if (nameindex == NULL)
		return false;

	@try {
		for (size_t i = 0; nameindex[i].if_index != 0; i++) {
			OFString *name = [OFString
			    stringWithCString: nameindex[i].if_name
				     encoding: encoding];
			OFNumber *index = [OFNumber
			    numberWithUnsignedInt: nameindex[i].if_index];
			OFMutableDictionary *interface =
			    [ret objectForKey: name];

			if (interface == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			[interface setObject: index
				      forKey: OFNetworkInterfaceIndex];
		}
	} @finally {
		if_freenameindex(nameindex);
	}

	return true;
# else
	return false;
# endif
}

static bool
queryNetworkInterfaceIPv6Addresses(OFMutableDictionary *ret)
{
# if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	OFFile *file;
	OFString *line;
	OFMutableDictionary *interface;
	OFEnumerator *enumerator;

	@try {
		file = [OFFile fileWithPath: @"/proc/net/if_inet6" mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		return false;
	}

	while ((line = [file readLine]) != nil) {
		OFArray *components = [line
		    componentsSeparatedByString: @" "
					options: OFStringSkipEmptyComponents];
		OFString *addressString, *name;
		OFSocketAddress address;
		OFMutableData *addresses;

		if (components.count < 6)
			continue;

		addressString = [components objectAtIndex: 0];
		name = [components objectAtIndex: 5];

		if (addressString.length != 32)
			continue;

		interface = [ret objectForKey: name];
		if (interface == nil) {
			interface = [OFMutableDictionary dictionary];
			[ret setObject: interface forKey: name];
		}

		memset(&address, 0, sizeof(address));
		address.family = OFSocketAddressFamilyIPv6;

		for (size_t i = 0; i < 32; i += 2) {
			unsigned long long byte;

			@try {
				byte = [[addressString
				    substringWithRange: OFMakeRange(i, 2)]
				    unsignedLongLongValueWithBase: 16];
			} @catch (OFInvalidFormatException *e) {
				goto next_line;
			}

			if (byte > 0xFF)
				goto next_line;

			address.sockaddr.in6.sin6_addr.s6_addr[i / 2] =
			    (unsigned char)byte;
		}

		addresses = [interface
		    objectForKey: OFNetworkInterfaceIPv6Addresses];
		if (addresses == nil) {
			addresses = [OFMutableData
			    dataWithItemSize: sizeof(OFSocketAddress)];
			[interface setObject: addresses
				      forKey: OFNetworkInterfaceIPv6Addresses];
		}

		[addresses addItem: &address];

next_line:
		continue;
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[[interface objectForKey: OFNetworkInterfaceIPv4Addresses]
		    makeImmutable];

	return false;
# else
	return false;
# endif
}

static bool
queryNetworkInterfaceIPv4Addresses(OFMutableDictionary *ret)
{
# if defined(HAVE_SYS_IOCTL_H) && defined(HAVE_NET_IF_H)
	OFStringEncoding encoding = [OFLocale encoding];
	int sock = socket(AF_INET, SOCK_DGRAM, 0);
	struct ifconf ifc;
	struct ifreq *ifrs;
	OFMutableDictionary *interface;
	OFEnumerator *enumerator;

	if (sock < 0)
		return false;

	ifrs = malloc(128 * sizeof(struct ifreq));
	if (ifrs == NULL) {
		closesocket(sock);
		return false;
	}

	@try {
		memset(&ifc, 0, sizeof(ifc));
		ifc.ifc_buf = (void *)ifrs;
		ifc.ifc_len = 128 * sizeof(struct ifreq);
		if (ioctl(sock, SIOCGIFCONF, &ifc) < 0)
			return false;

		for (size_t i = 0; i < ifc.ifc_len / sizeof(struct ifreq);
		    i++) {
			OFString *name;
			OFMutableData *addresses;
			OFSocketAddress address;

			if (ifrs[i].ifr_addr.sa_family != AF_INET)
				continue;

			name = [OFString stringWithCString: ifrs[i].ifr_name
						  encoding: encoding];
			interface = [ret objectForKey: name];
			if (interface == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			addresses = [interface
			    objectForKey: OFNetworkInterfaceIPv4Addresses];
			if (addresses == nil) {
				addresses = [OFMutableData
				    dataWithItemSize: sizeof(OFSocketAddress)];
				[interface
				    setObject: addresses
				       forKey: OFNetworkInterfaceIPv4Addresses];
			}

			memset(&address, 0, sizeof(address));
			address.family = OFSocketAddressFamilyIPv4;
			memcpy(&address.sockaddr.in, &ifrs[i].ifr_addr,
			    sizeof(struct sockaddr_in));

			[addresses addItem: &address];
		}
	} @finally {
		free(ifrs);
		closesocket(sock);
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[[interface objectForKey: OFNetworkInterfaceIPv4Addresses]
		    makeImmutable];

	return true;
# else
	return false;
# endif
}

+ (OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)networkInterfaces
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	bool success = false;
	OFEnumerator *enumerator;
	OFMutableDictionary *interface;

	success |= queryNetworkInterfaceIndices(ret);
	success |= queryNetworkInterfaceIPv6Addresses(ret);
	success |= queryNetworkInterfaceIPv4Addresses(ret);

	if (!success) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[interface makeImmutable];

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}
@end
