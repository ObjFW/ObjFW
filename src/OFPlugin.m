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

#import "config.h"

#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

#import "OFPlugin.h"
#import "OFExceptions.h"

@implementation OFPlugin
+ pluginFromFile: (const char*)path
{
	char *file;
	size_t pathlen, suffixlen;
	void *handle;
	OFPlugin *(*init_plugin)();
	OFPlugin *plugin;
	Class c;

	if ((self = [super init])) {
		pathlen = strlen(path);
		suffixlen = strlen(PLUGIN_SUFFIX);

		if ((file = malloc(pathlen + suffixlen + 1)) == NULL) {
			c = [self class];
			[super free];
			@throw [OFNoMemException newWithClass: c
						      andSize: pathlen +
							       suffixlen + 1];
		}
		memcpy(file, path, pathlen);
		memcpy(file + pathlen, PLUGIN_SUFFIX, suffixlen);
		file[pathlen + suffixlen] = 0;

		if ((handle = dlopen(file, RTLD_NOW)) == NULL) {
			free(file);
			c = [self class];
			[super free];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}
		free(file);

		if ((init_plugin = dlsym(handle, "init_plugin")) == NULL ||
		    (plugin = init_plugin()) == nil) {
			dlclose(handle);
			c = [self class];
			[super free];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}

		plugin->handle = handle;
		return plugin;
	}

	return self;
}

- free
{
	dlclose(handle);

	return [super free];
}
@end
