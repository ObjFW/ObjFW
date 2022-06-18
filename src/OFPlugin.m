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

#include "config.h"

#include <stdlib.h>
#include <string.h>

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFPlugin.h"
#import "OFLocale.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFLoadPluginFailedException.h"

#ifndef RTLD_LAZY
# define RTLD_LAZY 0
#endif

@implementation OFPlugin
+ (instancetype)pluginWithPath: (OFString *)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}

+ (OFString *)pathForName: (OFString *)name
{
#if defined(OF_MACOS)
	return [name stringByAppendingFormat: @".bundle/Contents/MacOS/%@",
					      name.lastPathComponent];
#elif defined(OF_IOS)
	return [name stringByAppendingFormat: @".bundle/%@",
					      name.lastPathComponent];
#else
	return [name stringByAppendingString: @PLUGIN_SUFFIX];
#endif
}

- (instancetype)initWithPath: (OFString *)path
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

#ifndef OF_WINDOWS
		_handle = dlopen(
		    [path cStringWithEncoding: [OFLocale encoding]], RTLD_LAZY);
#else
		if ([OFSystemInfo isWindowsNT])
			_handle = LoadLibraryW(path.UTF16String);
		else
			_handle = LoadLibraryA(
			    [path cStringWithEncoding: [OFLocale encoding]]);
#endif

		if (_handle == NULL) {
#ifndef OF_WINDOWS
			OFString *error = [OFString
			    stringWithCString: dlerror()
				     encoding: [OFLocale encoding]];
#else
			OFString *error = nil;
#endif
			@throw [OFLoadPluginFailedException
			    exceptionWithPath: path
					error: error];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void *)addressForSymbol: (OFString *)symbol
{
#ifndef OF_WINDOWS
	return dlsym(_handle,
	    [symbol cStringWithEncoding: [OFLocale encoding]]);
#else
	return (void *)(uintptr_t)GetProcAddress(_handle,
	    [symbol cStringWithEncoding: [OFLocale encoding]]);
#endif
}

- (void)dealloc
{
#ifndef OF_WINDOWS
	dlclose(_handle);
#else
	FreeLibrary(_handle);
#endif

	[super dealloc];
}
@end
