/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <unistd.h>

#import "OFSystemInfo.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFApplication.h"

#import "OFNotImplementedException.h"

#import "autorelease.h"
#import "macros.h"

#ifdef __APPLE__
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

static size_t pageSize;
static size_t numberOfCPUs;

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

+ (OFString*)userDataPath
{
#if defined(__APPLE__)
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
#if defined(__APPLE__)
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
@end
