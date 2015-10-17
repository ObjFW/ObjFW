/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#define __NO_EXT_QNX

#include "config.h"

/* Work around __block being used by glibc */
#include <stdlib.h>	/* include any libc header to get the libc defines */
#ifdef __GLIBC__
# undef __USE_XOPEN
#endif

#include <unistd.h>

#import "OFSystemInfo.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFApplication.h"

#import "OFNotImplementedException.h"

#if defined(__APPLE__) && !defined(OF_IOS)
# include <NSSystemDirectories.h>
#endif
#ifdef _WIN32
# include <windows.h>
#endif
#ifdef __HAIKU__
# include <FindDirectory.h>
#endif
#ifdef __QNX__
# include <sys/syspage.h>
#endif

#if defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
struct x86_regs {
	uint32_t eax, ebx, ecx, edx;
};
#endif

static size_t pageSize;
static size_t numberOfCPUs;

#if defined(OF_X86_64_ASM)
static OF_INLINE struct x86_regs OF_CONST_FUNC
x86_cpuid(uint32_t eax, uint32_t ecx)
{
	struct x86_regs regs;

	__asm__(
	    "cpuid"
	    : "=a"(regs.eax), "=b"(regs.ebx), "=c"(regs.ecx), "=d"(regs.edx)
	    : "a"(eax), "c"(ecx)
	);

	return regs;
}
#elif defined(OF_X86_ASM)
static OF_INLINE struct x86_regs OF_CONST_FUNC
x86_cpuid(uint32_t eax, uint32_t ecx)
{
	struct x86_regs regs;

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

	return regs;
}
#endif

@implementation OFSystemInfo
+ (void)initialize
{
	if (self != [OFSystemInfo class])
		return;

#if defined(_WIN32)
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	pageSize = si.dwPageSize;
	numberOfCPUs = si.dwNumberOfProcessors;
#elif defined(__QNX__)
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

+ (of_string_encoding_t)native8BitEncoding
{
	/* FIXME */
	return OF_STRING_ENCODING_UTF_8;
}

+ (OFString*)userDataPath
{
	/* TODO: Return something more sensible for iOS */
#if defined(__APPLE__) && !defined(OF_IOS)
	void *pool = objc_autoreleasePoolPush();
	char pathC[PATH_MAX];
	NSSearchPathEnumerationState state;
	OFMutableString *path;
	OFString *home;

	state = NSStartSearchPathEnumeration(NSApplicationSupportDirectory,
	    NSUserDomainMask);
	if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

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
#elif defined(_WIN32)
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	[appData retain];
	objc_autoreleasePoolPop(pool);
	return [appData autorelease];
#elif defined(__HAIKU__)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFString stringWithUTF8String: pathC];
#else
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
#endif
}

+ (OFString*)userConfigPath
{
	/* TODO: Return something more sensible for iOS */
#if defined(__APPLE__) && !defined(OF_IOS)
	void *pool = objc_autoreleasePoolPush();
	char pathC[PATH_MAX];
	NSSearchPathEnumerationState state;
	OFMutableString *path;
	OFString *home;

	state = NSStartSearchPathEnumeration(NSLibraryDirectory,
	    NSUserDomainMask);
	if (NSGetNextSearchPathEnumeration(state, pathC) == 0)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

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
#elif defined(_WIN32)
	void *pool = objc_autoreleasePoolPush();
	OFDictionary *env = [OFApplication environment];
	OFString *appData;

	if ((appData = [env objectForKey: @"APPDATA"]) == nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	[appData retain];
	objc_autoreleasePoolPop(pool);
	return [appData autorelease];
#elif defined(__HAIKU__)
	char pathC[PATH_MAX];

	if (find_directory(B_USER_SETTINGS_DIRECTORY, 0, false,
	    pathC, PATH_MAX) != B_OK)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	return [OFString stringWithUTF8String: pathC];
#else
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

#if defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
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
@end
