/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdlib.h>
#include <string.h>

#ifndef _WIN32
#include <dlfcn.h>
#endif

#import "OFPlugin.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#ifdef _WIN32
#define dlopen(file, mode) LoadLibrary(file)
#define dlsym(handle, symbol) GetProcAddress(handle, symbol)
#define dlclose(handle) FreeLibrary(handle)
#endif

@implementation OFPlugin
+ pluginFromFile: (OFString*)path
{
	OFAutoreleasePool *pool;
	OFString *file;
	of_plugin_handle_t handle;
	OFPlugin *(*init_plugin)();
	OFPlugin *plugin;

	pool = [[OFAutoreleasePool alloc] init];
	file = [OFMutableString stringWithString: path];
	[file appendCString: PLUGIN_SUFFIX];

	if ((handle = dlopen([file cString], RTLD_LAZY)) == NULL)
		@throw [OFInitializationFailedException newWithClass: self];

	[pool release];

	init_plugin = (OFPlugin*(*)())dlsym(handle, "init_plugin");
	if (init_plugin == NULL || (plugin = init_plugin()) == nil) {
		dlclose(handle);
		@throw [OFInitializationFailedException newWithClass: self];
	}

	plugin->handle = handle;
	return plugin;
}

- init
{
	if (isa == [OFPlugin class])
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	return [super init];
}

- (void)dealloc
{
	dlclose(handle);

	[super dealloc];
}
@end
