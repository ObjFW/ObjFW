/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdio.h>
#import "OFExceptions.h"

@implementation OFException
+ new: (id)obj
{
	return [[OFException alloc] init: obj];
}

- init: (id)obj
{
	return [super init];
}
@end

@implementation OFNoMemException
+      new: (id)obj
  withSize: (size_t)size
{
	return [[OFNoMemException alloc] init: obj
				     withSize: size];
}

-     init: (id)obj
  withSize: (size_t)size
{
	fprintf(stderr, "ERROR: Could not allocate %zu bytes for object %s!\n",
	    size, [obj name]);
	return [super init];
}
@end

@implementation OFNotImplementedException
+        new: (id)obj
  withMethod: (const char*)method
{
	return [[OFNotImplementedException alloc] init: obj
					    withMethod: method];
}

-       init: (id)obj
  withMethod: (const char*)method
{
	fprintf(stderr, "ERROR: Requested method %s not implemented in %s!\n",
	    method, [obj name]);
	return [super init];
}
@end

@implementation OFMemNotPartOfObjException
+     new: (id)obj
  withPtr: (void*)ptr
{
	return [[OFMemNotPartOfObjException alloc] init: obj
						withPtr: ptr];
}

-    init: (id)obj
  withPtr: (void*)ptr
{
	fprintf(stderr, "ERROR: Memory at %p was not allocated as part of "
	    "object %s!\n"
	    "ERROR: -> Not changing memory allocation!\n"
	    "ERROR: (Hint: It is possible that you tried to free the same "
	    "memory twice!)\n", ptr, [obj name]);

	return [super init];
}
@end
