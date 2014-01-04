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

#include "config.h"

#include <stdlib.h>
#include <string.h>

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#endif

#import "OFPlugin.h"
#import "OFString.h"

#import "OFInitializationFailedException.h"

#import "autorelease.h"

#ifdef _WIN32
# define dlsym(handle, symbol) GetProcAddress(handle, symbol)
# define dlclose(handle) FreeLibrary(handle)
#endif

@implementation OFPlugin
+ (id)pluginFromFile: (OFString*)path
{
	void *pool = objc_autoreleasePoolPush();
	of_plugin_handle_t handle;
	OFPlugin *(*initPlugin)(void);
	OFPlugin *plugin;

	path = [path stringByAppendingString: @PLUGIN_SUFFIX];

#ifndef _WIN32
	if ((handle = dlopen([path cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE], RTLD_LAZY)) == NULL)
#else
	if ((handle = LoadLibraryW([path UTF16String])) == NULL)
#endif
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	objc_autoreleasePoolPop(pool);

	initPlugin = (OFPlugin*(*)(void))dlsym(handle, "init_plugin");
	if (initPlugin == NULL || (plugin = initPlugin()) == nil) {
		dlclose(handle);
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	}

	plugin->_handle = handle;
	return plugin;
}

- init
{
	if (object_getClass(self) == [OFPlugin class]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	return [super init];
}

- (void)dealloc
{
	of_plugin_handle_t h = _handle;

	[super dealloc];

	dlclose(h);
}
@end
