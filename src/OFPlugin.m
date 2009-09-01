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
#include <dlfcn.h>

#import "OFPlugin.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

@implementation OFPlugin
+ pluginFromFile: (OFString*)path
{
	OFAutoreleasePool *pool;
	OFString *file;
	void *handle;
	OFPlugin *(*init_plugin)();
	OFPlugin *plugin;

	pool = [[OFAutoreleasePool alloc] init];
	file = [OFMutableString stringWithString: path];
	[file appendCString: PLUGIN_SUFFIX];

	if ((handle = dlopen([file cString], RTLD_LAZY)) == NULL)
		@throw [OFInitializationFailedException newWithClass: self];

	[pool release];

	if ((init_plugin = dlsym(handle, "init_plugin")) == NULL ||
	    (plugin = init_plugin()) == nil) {
		dlclose(handle);
		@throw [OFInitializationFailedException newWithClass: self];
	}

	plugin->handle = handle;
	return [plugin autorelease];
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
