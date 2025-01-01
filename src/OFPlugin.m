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

#include <stdlib.h>
#include <string.h>

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFPlugin.h"
#import "OFFileManager.h"
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
#if (defined(OF_MACOS) || defined(OF_IOS)) && defined(OF_HAVE_FILES)
	OFString *path = [name stringByAppendingPathExtension: @"bundle"];

	if ([[OFFileManager defaultManager] directoryExistsAtPath: path])
# if defined(OF_MACOS)
		return [path stringByAppendingFormat: @"/Contents/MacOS/%@",
						      name.lastPathComponent];
# elif defined(OF_IOS)
		return [name stringByAppendingFormat: @"/%@",
						      name.lastPathComponent];
# endif
#endif

	return [name stringByAppendingString: @PLUGIN_SUFFIX];
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
		if (path != nil) {
			if ([OFSystemInfo isWindowsNT])
				_handle = LoadLibraryW(path.UTF16String);
			else
				_handle = LoadLibraryA([path
				    cStringWithEncoding: [OFLocale encoding]]);
		} else
			_handle = GetModuleHandle(NULL);
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
