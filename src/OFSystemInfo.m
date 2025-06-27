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

#include <limits.h>	/* include any libc header to get the libc defines */
#include <setjmp.h>
#include <signal.h>

#include "unistd_wrapper.h"

#include "platform.h"

#ifdef HAVE_SYS_UTSNAME_H
# include <sys/utsname.h>
#endif
#if defined(OF_MACOS) || defined(OF_IOS) || defined(OF_NETBSD)
# include <sys/sysctl.h>
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
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFIRI.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFOnce.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

#if defined(OF_MACOS) || defined(OF_IOS)
# ifdef HAVE_SYSDIR_H
#  include <sysdir.h>
# endif
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

#if defined(OF_AMD64) || defined(OF_X86)
struct X86Regs {
	uint32_t eax, ebx, ecx, edx;
};

static bool SSESupport;
static jmp_buf SSETestEnv;

static void
SSETestSIGILLHandler(int signum)
{
	longjmp(SSETestEnv, 1);
}

# ifndef __clang__
#  pragma GCC push_options
#  pragma GCC target("sse")
# endif
static void
SSETest(void)
{
	void (*oldHandler)(int) = signal(SIGILL, SSETestSIGILLHandler);

	if (setjmp(SSETestEnv) == 0) {
		__asm__ __volatile__ (
		    "movaps	%%xmm0, %%xmm0"
		    ::: "xmm0"	/* clang is unhappy if we don't clobber it */
		);
		SSESupport = true;
	} else
		SSESupport = false;

	signal(SIGILL, oldHandler);
}
# ifndef __clang__
#  pragma GCC pop_options
# endif
#endif

static size_t pageSize = 4096;
static size_t numberOfCPUs = 1;
static OFString *operatingSystemName = nil;
static OFString *operatingSystemVersion = nil;

#ifdef OF_WINDOWS
static const char *(*wine_get_version)(void);
#endif

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

	if (uname(&name) == -1)
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

	if (uname(&name) == -1)
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
	    : "=a" (regs.eax),
	      "=b" (regs.ebx),
	      "=c" (regs.ecx),
	      "=d" (regs.edx)
	    : "a" (eax),
	      "c" (ecx)
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
	    : "=a" (regs.eax),
	      "=D" (regs.ebx),
	      "=c" (regs.ecx),
	      "=d" (regs.edx)
	    : "a" (eax),
	      "c" (ecx)
	);
# else
	memset(&regs, 0, sizeof(regs));
# endif

	return regs;
}

static OF_INLINE struct X86Regs
x86XCR(uint32_t ecx)
{
	struct X86Regs regs = { 0 };

	if (!(x86CPUID(1, 0).ecx & (1u << 27)))
		return regs;

	__asm__ (
	    "xgetbv"
	    : "=a" (regs.eax),
	      "=d" (regs.edx)
	    : "c" (ecx)
	);

	return regs;
}
#endif

#ifdef OF_LOONGARCH64
static uint32_t
cpucfg(uint32_t word)
{
	uint32_t ret;

	__asm__ (
	    "cpucfg	%0, %1"
	    : "=r" (ret)
	    : "r" (word)
	);

	return ret;
}
#endif

@implementation OFSystemInfo
+ (void)initialize
{
	long tmp;

	if (self != [OFSystemInfo class])
		return;

#if defined(OF_AMD64) || defined(OF_X86)
	/*
	 * Do this as early as possible, as it involves signals.
	 * Required as cpuid can return SSE support while the OS has not
	 * enabled it.
	 */
	SSETest();
#endif

#if defined(OF_WINDOWS)
	HANDLE module;

	SYSTEM_INFO si;
	GetSystemInfo(&si);
	pageSize = si.dwPageSize;
	numberOfCPUs = si.dwNumberOfProcessors;

	if ((module = GetModuleHandle("ntdll.dll")) != NULL)
		wine_get_version = (const char *(*)(void))
		    GetProcAddress(module, "wine_get_version");
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

#ifdef OF_WINDOWS
+ (OFString *)wineVersion
{
	if (wine_get_version != NULL)
		return [OFString stringWithCString: wine_get_version()
					  encoding: [OFLocale encoding]];

	return nil;
}
#endif

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
# elif defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	return [[OFFileManager defaultManager] currentDirectoryIRI];
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

	return objc_autoreleaseReturnValue(IRI);
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
# elif defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	return [[OFFileManager defaultManager] currentDirectoryIRI];
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
# elif defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS)
	return [[OFFileManager defaultManager] currentDirectoryIRI];
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

	if (length > 0 && buffer[length - 1] == '\0')
		length--;

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
	return (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).edx & (1u << 23));
}

+ (bool)supports3DNow
{
	return (x86CPUID(0x80000000, 0).eax >= 0x80000001 &&
	    x86CPUID(0x80000001, 0).edx & (1u << 31));
}

+ (bool)supportsEnhanced3DNow
{
	return (x86CPUID(0x80000000, 0).eax >= 0x80000001 &&
	    x86CPUID(0x80000001, 0).edx & (1u << 30));
}

+ (bool)supportsSSE
{
	return SSESupport &&
	    (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).edx & (1u << 25));
}

+ (bool)supportsSSE2
{
	return SSESupport &&
	    (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).edx & (1u << 26));
}

+ (bool)supportsSSE3
{
	return SSESupport &&
	    (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 0));
}

+ (bool)supportsSSSE3
{
	return SSESupport &&
	    (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 9));
}

+ (bool)supportsSSE41
{
	return SSESupport &&
	    (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 19));
}

+ (bool)supportsSSE42
{
	return SSESupport &&
	    (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 20));
}

+ (bool)supportsAVX
{
	return ((x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 28)) &&
	    (x86XCR(0).eax & 0x6) == 0x6);
}

+ (bool)supportsAVX2
{
	return ((x86CPUID(0, 0).eax >= 7 && (x86CPUID(7, 0).ebx & (1u << 5))) &&
	    (x86XCR(0).eax & 0x6) == 0x6);
}

+ (bool)supportsAESNI
{
	return (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 25));
}

+ (bool)supportsSHAExtensions
{
	return (x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 29));
}

+ (bool)supportsFusedMultiplyAdd
{
	return (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 12));
}

+ (bool)supportsF16C
{
	return (x86CPUID(0, 0).eax >= 1 && x86CPUID(1, 0).ecx & (1u << 29));
}

+ (bool)supportsAVX512Foundation
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 16)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512ConflictDetectionInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 28)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512ExponentialAndReciprocalInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 27)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512PrefetchInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 26)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512VectorLengthExtensions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 31)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512DoublewordAndQuadwordInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 17)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512ByteAndWordInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 30)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512IntegerFusedMultiplyAdd
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ebx & (1u << 21)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512VectorByteManipulationInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ecx & (1u << 1)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512VectorPopulationCountInstruction
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ecx & (1u << 14)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512VectorNeuralNetworkInstructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ecx & (1u << 11)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512VectorByteManipulationInstructions2
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ecx & (1u << 6)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512BitAlgorithms
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).ecx & (1u << 12)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512Float16Instructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 0).edx & (1u << 23)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
}

+ (bool)supportsAVX512BFloat16Instructions
{
	return ((x86CPUID(0, 0).eax >= 7 && x86CPUID(7, 1).eax & (1u << 5)) &&
	    (x86XCR(0).eax & 0xE6) == 0xE6);
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

#ifdef OF_LOONGARCH64
+ (bool)supportsLSX
{
	return cpucfg(2) & (1 << 6);
}

+ (bool)supportsLASX
{
	return cpucfg(2) & (1 << 7);
}
#endif

#ifdef OF_WINDOWS
+ (bool)isWindowsNT
{
	return !(GetVersion() & 0x80000000);
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}
@end
