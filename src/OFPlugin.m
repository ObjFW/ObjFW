/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFLocale.h"

#import "OFInitializationFailedException.h"
#import "OFLoadPluginFailedException.h"

typedef OFPlugin *(*init_plugin_t)(void);

of_plugin_handle_t
of_dlopen(OFString *path, int flags)
{
#ifndef OF_WINDOWS
	return dlopen([path cStringWithEncoding: [OFLocale encoding]], flags);
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

OFString *
of_dlerror(void)
{
#ifndef OF_WINDOWS
	return [OFString stringWithCString: dlerror()
				  encoding: [OFLocale encoding]];
#else
	return nil;
#endif
}

@implementation OFPlugin
+ (id)pluginFromFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	of_plugin_handle_t handle;
	init_plugin_t initPlugin;
	OFPlugin *plugin;

#if defined(OF_MACOS)
	path = [path stringByAppendingFormat: @".bundle/Contents/MacOS/%@",
					      [path lastPathComponent]];
#elif defined(OF_IOS)
	path = [path stringByAppendingFormat: @".bundle/%@",
					      [path lastPathComponent]];
#else
	path = [path stringByAppendingString: @PLUGIN_SUFFIX];
#endif

	if ((handle = of_dlopen(path, OF_RTLD_LAZY)) == NULL)
		@throw [OFLoadPluginFailedException
		    exceptionWithPath: path
				error: of_dlerror()];

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
