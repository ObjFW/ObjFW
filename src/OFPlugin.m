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
	return [[[OFPlugin alloc] initFromFile: path] autorelease];
}

- initFromFile: (const char*)path
{
	char *file;
	size_t pathlen, suffixlen;
	id (*init_plugin)();
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

		if ((handle = dlopen(file, RTLD_NOW)) == NULL ||
		    (init_plugin = dlsym(handle, "init_plugin")) == NULL ||
		    (plugin = init_plugin()) == nil) {
			free(file);
			c = [self class];
			[super free];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}
		free(file);
	}

	return self;
}

- free
{
	[plugin free];
	dlclose(handle);

	return [super free];
}

#ifdef __objc_INCLUDE_GNU
- (retval_t)forward: (SEL)selector
		   : (arglist_t)args
#else
- (id)forward: (SEL)selector
	     : (marg_list)args
#endif
{
	return [plugin performv: selector
			       : args];
}

- (IMP)methodFor: (SEL)selector
{
	if ([self respondsTo: selector])
		return [self methodFor: selector];
	else
		return [plugin methodFor: selector];
}
@end
