/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include <stdlib.h>	/* include any libc header to get the libc defines */

#include "unistd_wrapper.h"

#include "platform.h"

#ifdef OF_MACOS
# include <sys/sysctl.h>
#endif

#ifdef OF_MORPHOS
# define BOOL EXEC_BOOL
# include <exec/system.h>
# include <proto/exec.h>
# undef BOOL
#endif

#import "OFSystemInfo.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFApplication.h"

#import "OFNotImplementedException.h"

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

#if defined(OF_X86_64) || defined(OF_X86)
struct x86_regs {
	uint32_t eax, ebx, ecx, edx;
};
#endif

static size_t pageSize;
static size_t numberOfCPUs;

#if defined(OF_X86_64) || defined(OF_X86)
static OF_INLINE struct x86_regs OF_CONST_FUNC
x86_cpuid(uint32_t eax, uint32_t ecx)
{
	struct x86_regs regs;

# if defined(OF_X86_64_ASM)
	__asm__(
	    "cpuid"
	    : "=a"(regs.eax), "=b"(regs.ebx), "=c"(regs.ecx), "=d"(regs.edx)
	    : "a"(eax), "c"(ecx)
	);
# elif defined(OF_X86_ASM)
	/*
	 * This workaround is required by GCC when using -fPIC, as ebx is a
	 * special register in PIC code. Yes, GCC is indeed not able to just
	 * push a register onto the stack before the __asm__ block and to pop
	 * it afterwards.
	 */
	__asm__(
	    "pushl	%%ebx\n\t"
	    "cpuid\n\t"
	    "movl	%%ebx, %1\n\t"
	    "popl	%%ebx"
	    : "=a"(regs.eax), "=r"(regs.ebx), "=c"(regs.ecx), "=d"(regs.edx)
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
	if (self != [OFSystemInfo class])
		return;

#if defined(OF_WINDOWS)
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	pageSize = si.dwPageSize;
	numberOfCPUs = si.dwNumberOfProcessors;
#elif defined(OF_QNX)
	if ((pageSize = sysconf(_SC_PAGESIZE)) < 1)
		pageSize = 4096;
	numberOfCPUs = _syspage_ptr->num_cpu;
#else
# if defined(HAVE_SYSCONF) && defined(_SC_PAGESIZE)
	if ((pageSize = sysconf(_SC_PAGESIZE)) < 1)
# endif
		pageSize = 4096;
# if defined(HAVE_SYSCONF) && defined(_SC_NPROCESSORS_CONF)
	if ((numberOfCPUs = sysconf(_SC_NPROCESSORS_CONF)) < 1)
# endif
		numberOfCPUs = 1;
#endif
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

+ (OFString *)userDataPath
{
#if defined(OF_MACOS) || defined(OF_IOS)
	char pathC[PATH_MAX];
	OFMutableString *path;

# ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	/* (1) to disable dead code warning when it is not a weak symbol */
	if ((1) && &sysdir_start_search_path_enumeration != NULL) {
		sysdir_search_path_enumeration_state state;

		state = sysdir_start_search_path_enumeration(
		    SYSDIR_DIRECTORY_APPLICATION_SUPPORT,
		    SYSDIR_DOMAIN_MASK_USER);
		if (sysdir_get_next_search_path_enumeration(state, pathC) == 0)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
	} else {
# endif
		NSSearchPathEnumerationState state;

		state = NSStartSearchPathEnumeration(
		    NSApplicationSupportDirectory, NSUserDomainMask);
		if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
# ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	}
# endif

	path = [OFMutableString stringWithUTF8String: pathC];
	if ([path hasPrefix: @"~"]) {
		OFDictionary *env = [OFApplication environment];
		OFString *home;

		if ((home = [env objectForKey: @"HOME"]) == nil)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		[path deleteCharactersInRange: of_range(0, 1)];
		[path prependString: home];
	}

	[path makeImmutable];

	return path;
#elif defined(OF_WINDOWS)
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return appData;
#elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFString stringWithUTF8String: pathC];
#else
	OFDictionary *env = [OFApplication environment];
	OFString *var;
	void *pool;

	if ((var = [env objectForKey: @"XDG_DATA_HOME"]) != nil &&
	    [var length] > 0)
		return var;

	if ((var = [env objectForKey: @"HOME"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	pool = objc_autoreleasePoolPush();

	var = [[OFString pathWithComponents: [OFArray arrayWithObjects:
	    var, @".local", @"share", nil]] retain];

	objc_autoreleasePoolPop(pool);

	return [var autorelease];
#endif
}

+ (OFString *)userConfigPath
{
#if defined(OF_MACOS) || defined(OF_IOS)
	char pathC[PATH_MAX];
	OFMutableString *path;

# ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	/* (1) to disable dead code warning when it is not a weak symbol */
	if ((1) && &sysdir_start_search_path_enumeration != NULL) {
		sysdir_search_path_enumeration_state state;

		state = sysdir_start_search_path_enumeration(
		    SYSDIR_DIRECTORY_LIBRARY, SYSDIR_DOMAIN_MASK_USER);
		if (sysdir_get_next_search_path_enumeration(state, pathC) == 0)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
	} else {
# endif
		NSSearchPathEnumerationState state;

		state = NSStartSearchPathEnumeration(NSLibraryDirectory,
		    NSUserDomainMask);
		if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
# ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	}
# endif

	path = [OFMutableString stringWithUTF8String: pathC];
	if ([path hasPrefix: @"~"]) {
		OFDictionary *env = [OFApplication environment];
		OFString *home;

		if ((home = [env objectForKey: @"HOME"]) == nil)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		[path deleteCharactersInRange: of_range(0, 1)];
		[path prependString: home];
	}

	[path appendString: @"/Preferences"];

	[path makeImmutable];

	return path;
#elif defined(OF_WINDOWS)
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return appData;
#elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFString stringWithUTF8String: pathC];
#else
	OFDictionary *env = [OFApplication environment];
	OFString *var;

	if ((var = [env objectForKey: @"XDG_CONFIG_HOME"]) != nil &&
	    [var length] > 0)
		return var;

	if ((var = [env objectForKey: @"HOME"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [var stringByAppendingPathComponent: @".config"];
#endif
}

+ (OFString *)CPUVendor
{
#if defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	struct x86_regs regs = x86_cpuid(0, 0);
	char buffer[12];

	if (regs.eax == 0)
		return nil;

	memcpy(buffer, &regs.ebx, 4);
	memcpy(buffer + 4, &regs.edx, 4);
	memcpy(buffer + 8, &regs.ecx, 4);

	return [OFString stringWithCString: buffer
				  encoding: OF_STRING_ENCODING_ASCII
				    length: 12];
#else
	return nil;
#endif
}

#if defined(OF_X86_64) || defined(OF_X86)
+ (bool)supportsMMX
{
	return (x86_cpuid(1, 0).edx & (1 << 23));
}

+ (bool)supportsSSE
{
	return (x86_cpuid(1, 0).edx & (1 << 25));
}

+ (bool)supportsSSE2
{
	return (x86_cpuid(1, 0).edx & (1 << 26));
}

+ (bool)supportsSSE3
{
	return (x86_cpuid(1, 0).ecx & (1 << 0));
}

+ (bool)supportsSSSE3
{
	return (x86_cpuid(1, 0).ecx & (1 << 9));
}

+ (bool)supportsSSE41
{
	return (x86_cpuid(1, 0).ecx & (1 << 19));
}

+ (bool)supportsSSE42
{
	return (x86_cpuid(1, 0).ecx & (1 << 20));
}

+ (bool)supportsAVX
{
	return (x86_cpuid(1, 0).ecx & (1 << 28));
}

+ (bool)supportsAVX2
{
	return x86_cpuid(0, 0).eax >= 7 && (x86_cpuid(7, 0).ebx & (1 << 5));
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
# elif defined(OF_MORPHOS)
	uint32_t supportsAltiVec;

	if (NewGetSystemAttrs(&supportsAltiVec, sizeof(supportsAltiVec),
	    SYSTEMINFOTYPE_PPC_ALTIVEC, TAG_DONE) > 0)
		return supportsAltiVec;

	return false;
# endif

	return false;
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}
@end
