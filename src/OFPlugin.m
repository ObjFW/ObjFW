/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

typedef OFPlugin *(*init_plugin_t)(void);

OFPluginHandle
OFDlopen(OFString *path, int flags)
{
#ifndef OF_WINDOWS
	return dlopen([path cStringWithEncoding: [OFLocale encoding]], flags);
#else
	if (path == nil)
		return GetModuleHandle(NULL);

	if ([OFSystemInfo isWindowsNT])
		return LoadLibraryW(path.UTF16String);
	else
		return LoadLibraryA(
		    [path cStringWithEncoding: [OFLocale encoding]]);
#endif
}

void *
OFDlsym(OFPluginHandle handle, const char *symbol)
{
#ifndef OF_WINDOWS
	return dlsym(handle, symbol);
#else
	return (void *)(uintptr_t)GetProcAddress(handle, symbol);
#endif
}

void
OFDlclose(OFPluginHandle handle)
{
#ifndef OF_WINDOWS
	dlclose(handle);
#else
	FreeLibrary(handle);
#endif
}

OFString *
OFDlerror(void)
{
#ifndef OF_WINDOWS
	return [OFString stringWithCString: dlerror()
				  encoding: [OFLocale encoding]];
#else
	return nil;
#endif
}

@implementation OFPlugin
+ (id)pluginWithPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFPluginHandle handle;
	init_plugin_t initPlugin;
	OFPlugin *plugin;

#if defined(OF_MACOS)
	path = [path stringByAppendingFormat: @".bundle/Contents/MacOS/%@",
					      path.lastPathComponent];
#elif defined(OF_IOS)
	path = [path stringByAppendingFormat: @".bundle/%@",
					      path.lastPathComponent];
#else
	path = [path stringByAppendingString: @PLUGIN_SUFFIX];
#endif

	if ((handle = OFDlopen(path, OF_RTLD_LAZY)) == NULL)
		@throw [OFLoadPluginFailedException
		    exceptionWithPath: path
				error: OFDlerror()];

	objc_autoreleasePoolPop(pool);

	initPlugin = (init_plugin_t)(uintptr_t)OFDlsym(handle, "init_plugin");
	if (initPlugin == (init_plugin_t)0 || (plugin = initPlugin()) == nil) {
		OFDlclose(handle);
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	}

	plugin->_pluginHandle = handle;
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
	OFPluginHandle h = _pluginHandle;

	[super dealloc];

	OFDlclose(h);
}
@end
