/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

/* Work around __block being used by glibc */
#include <stdlib.h>	/* include any libc header to get the libc defines */
#ifdef __GLIBC__
# undef __USE_XOPEN
#endif

#include <unistd.h>

#include "platform.h"

#ifdef OF_MAC_OS_X
# include <sys/sysctl.h>
#endif

#import "OFSystemInfo.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFApplication.h"

#import "OFNotImplementedException.h"

#if defined(OF_MAC_OS_X) || defined(OF_IOS)
# ifdef HAVE_SYSDIR_H
#  include <sysdir.h>
# else
#  include <NSSystemDirectories.h>
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

+ alloc
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

+ (OFString*)userDataPath
{
#if defined(OF_MAC_OS_X) || defined(OF_IOS)
	void *pool = objc_autoreleasePoolPush();
	char pathC[PATH_MAX];
	OFMutableString *path;
	OFString *home;

# ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	sysdir_search_path_enumeration_state state;

	state = sysdir_start_search_path_enumeration(
	    SYSDIR_DIRECTORY_APPLICATION_SUPPORT, SYSDIR_DOMAIN_MASK_USER);
	if (sysdir_get_next_search_path_enumeration(state, pathC) == 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
# else
	NSSearchPathEnumerationState state;

	state = NSStartSearchPathEnumeration(NSApplicationSupportDirectory,
	    NSUserDomainMask);
	if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
# endif

	path = [OFMutableString stringWithUTF8String: pathC];
	if ([path hasPrefix: @"~"]) {
		OFDictionary *env = [OFApplication environment];

		if ((home = [env objectForKey: @"HOME"]) == nil)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		[path deleteCharactersInRange: of_range(0, 1)];
		[path prependString: home];
	}

	[path makeImmutable];

	[path retain];
	objc_autoreleasePoolPop(pool);
	return [path autorelease];
#elif defined(OF_WINDOWS)
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	[appData retain];
	objc_autoreleasePoolPop(pool);
	return [appData autorelease];
#elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFString stringWithUTF8String: pathC];
#elif !defined(OF_IOS)
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *env = [OFApplication environment];
	OFString *var;

	if ((var = [env objectForKey: @"XDG_DATA_HOME"]) != nil &&
	    [var length] > 0) {
		[var retain];
		objc_autoreleasePoolPop(pool);
		return [var autorelease];
	}

	if ((var = [env objectForKey: @"HOME"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	var = [OFString pathWithComponents: [OFArray arrayWithObjects:
	    var, @".local", @"share", nil]];

	[var retain];
	objc_autoreleasePoolPop(pool);
	return [var autorelease];
#else
	@throw [OFNotImplementedException exceptionWithSelector: _cmd
							 object: self];
#endif
}

+ (OFString*)userConfigPath
{
#if defined(OF_MAC_OS_X) || defined(OF_IOS)
	void *pool = objc_autoreleasePoolPush();
	char pathC[PATH_MAX];
	OFMutableString *path;
	OFString *home;

# ifdef HAVE_SYSDIR_START_SEARCH_PATH_ENUMERATION
	sysdir_search_path_enumeration_state state;

	state = sysdir_start_search_path_enumeration(
	    SYSDIR_DIRECTORY_LIBRARY, SYSDIR_DOMAIN_MASK_USER);
	if (sysdir_get_next_search_path_enumeration(state, pathC) == 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
# else
	NSSearchPathEnumerationState state;

	state = NSStartSearchPathEnumeration(NSLibraryDirectory,
	    NSUserDomainMask);
	if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
# endif

	path = [OFMutableString stringWithUTF8String: pathC];
	if ([path hasPrefix: @"~"]) {
		OFDictionary *env = [OFApplication environment];

		if ((home = [env objectForKey: @"HOME"]) == nil)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		[path deleteCharactersInRange: of_range(0, 1)];
		[path prependString: home];
	}

	[path appendString: @"/Preferences"];

	[path makeImmutable];

	[path retain];
	objc_autoreleasePoolPop(pool);
	return [path autorelease];
#elif defined(OF_WINDOWS)
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	[appData retain];
	objc_autoreleasePoolPop(pool);
	return [appData autorelease];
#elif defined(OF_HAIKU)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFString stringWithUTF8String: pathC];
#elif !defined(OF_IOS)
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *env = [OFApplication environment];
	OFString *var;

	if ((var = [env objectForKey: @"XDG_CONFIG_HOME"]) != nil &&
	    [var length] > 0) {
		[var retain];
		objc_autoreleasePoolPop(pool);
		return [var autorelease];
	}

	if ((var = [env objectForKey: @"HOME"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	var = [var stringByAppendingPathComponent: @".config"];

	[var retain];
	objc_autoreleasePoolPop(pool);
	return [var autorelease];
#else
	@throw [OFNotImplementedException OFNotImplementedException: _cmd
							     object: self];
#endif
}

+ (OFString*)CPUVendor
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
# ifdef OF_MAC_OS_X
	int name[2] = { CTL_HW, HW_VECTORUNIT }, value = 0;
	size_t length = sizeof(value);

	if (sysctl(name, 2, &value, &length, NULL, 0) == 0)
		return value;
# endif

	return 0;
}
#endif
@end
