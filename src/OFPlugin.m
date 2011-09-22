/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#ifndef _WIN32
#include <dlfcn.h>
#endif

#import "OFPlugin.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"

#ifdef _WIN32
# define dlopen(file, mode) LoadLibrary(file)
# define dlsym(handle, symbol) GetProcAddress(handle, symbol)
# define dlclose(handle) FreeLibrary(handle)
#endif

@implementation OFPlugin
+ pluginFromFile: (OFString*)path
{
	OFAutoreleasePool *pool;
	OFMutableString *file;
	of_plugin_handle_t handle;
	OFPlugin *(*initPlugin)();
	OFPlugin *plugin;

	pool = [[OFAutoreleasePool alloc] init];
	file = [OFMutableString stringWithString: path];
	[file appendString: @PLUGIN_SUFFIX];

	if ((handle = dlopen([file cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE], RTLD_LAZY)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	[pool release];

	initPlugin = (OFPlugin*(*)())dlsym(handle, "init_plugin");
	if (initPlugin == NULL || (plugin = initPlugin()) == nil) {
		dlclose(handle);
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	}

	plugin->handle = handle;
	return plugin;
}

- init
{
	if (isa == [OFPlugin class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	return [super init];
}

- (void)dealloc
{
	of_plugin_handle_t h = handle;

	[super dealloc];

	dlclose(h);
}
@end
