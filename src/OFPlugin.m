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

#include "config.h"

#include <stdlib.h>
#include <string.h>

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFPlugin.h"
#import "OFString.h"
#import "OFLocalization.h"

#import "OFInitializationFailedException.h"
#import "OFOpenItemFailedException.h"

typedef OFPlugin *(*init_plugin_t)(void);

of_plugin_handle_t
of_dlopen(OFString *path, int flags)
{
#ifndef OF_WINDOWS
	return dlopen([path cStringWithEncoding: [OFLocalization encoding]],
	    flags);
#else
	if (path == nil)
		return GetModuleHandle(NULL);

	return LoadLibraryW([path UTF16String]);
#endif
}

void *
of_dlsym(of_plugin_handle_t handle, const char *symbol)
{
#ifndef OF_WINDOWS
	return dlsym(handle, symbol);
#else
	return (void *)(uintptr_t)GetProcAddress(handle, symbol);
#endif
}

void
of_dlclose(of_plugin_handle_t handle)
{
#ifndef OF_WINDOWS
	dlclose(handle);
#else
	FreeLibrary(handle);
#endif
}

@implementation OFPlugin
+ (id)pluginFromFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	of_plugin_handle_t handle;
	init_plugin_t initPlugin;
	OFPlugin *plugin;

	path = [path stringByAppendingString: @PLUGIN_SUFFIX];

	if ((handle = of_dlopen(path, OF_RTLD_LAZY)) == NULL)
		@throw [OFOpenItemFailedException exceptionWithPath: path
							       mode: nil
							      errNo: 0];

	objc_autoreleasePoolPop(pool);

	initPlugin = (init_plugin_t)(uintptr_t)of_dlsym(handle, "init_plugin");
	if (initPlugin == (init_plugin_t)0 || (plugin = initPlugin()) == nil) {
		of_dlclose(handle);
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	}

	plugin->_handle = handle;
	return plugin;
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFPlugin class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (void)dealloc
{
	of_plugin_handle_t h = _handle;

	[super dealloc];

	of_dlclose(h);
}
@end
