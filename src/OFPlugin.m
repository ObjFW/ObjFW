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
#import "OFExceptions.h"

@implementation OFPlugin
+ pluginFromFile: (OFString*)path
{
	char *file;
	size_t pathlen, suffixlen;
	void *handle;
	OFPlugin *(*init_plugin)();
	OFPlugin *plugin;

	pathlen = [path length];
	suffixlen = strlen(PLUGIN_SUFFIX);

	if ((file = malloc(pathlen + suffixlen + 1)) == NULL) {
		@throw [OFOutOfMemoryException newWithClass: self
						       size: pathlen +
							     suffixlen + 1];
	}
	memcpy(file, [path cString], pathlen);
	memcpy(file + pathlen, PLUGIN_SUFFIX, suffixlen);
	file[pathlen + suffixlen] = 0;

	if ((handle = dlopen(file, RTLD_NOW)) == NULL) {
		free(file);
		@throw [OFInitializationFailedException newWithClass: self];
	}
	free(file);

	if ((init_plugin = dlsym(handle, "init_plugin")) == NULL ||
	    (plugin = init_plugin()) == nil) {
		dlclose(handle);
		@throw [OFInitializationFailedException newWithClass: self];
	}

	plugin->handle = handle;
	return [plugin autorelease];
}

- (void)dealloc
{
	dlclose(handle);

	[super dealloc];
}
@end
