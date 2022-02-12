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

typedef OFPlugin *(*PluginInit)(void);

OFPluginHandle
OFDLOpen(OFString *path, OFDLOpenFlags flags)
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
OFDLSym(OFPluginHandle handle, const char *symbol)
{
#ifndef OF_WINDOWS
	return dlsym(handle, symbol);
#else
	return (void *)(uintptr_t)GetProcAddress(handle, symbol);
#endif
}

void
OFDLClose(OFPluginHandle handle)
{
#ifndef OF_WINDOWS
	dlclose(handle);
#else
	FreeLibrary(handle);
#endif
}

OFString *
OFDLError(void)
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
	PluginInit initPlugin;
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

	if ((handle = OFDLOpen(path, OFDLOpenFlagLazy)) == NULL)
		@throw [OFLoadPluginFailedException
		    exceptionWithPath: path
				error: OFDLError()];

	objc_autoreleasePoolPop(pool);

	initPlugin = (PluginInit)(uintptr_t)OFDLSym(handle, "OFPluginInit");
	if (initPlugin == (PluginInit)0 || (plugin = initPlugin()) == nil) {
		OFDLClose(handle);
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

	OFDLClose(h);
}
@end
