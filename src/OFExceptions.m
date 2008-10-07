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
+ newWithObject: (id)obj
{
	return [[OFException alloc] initWithObject: obj];
}

- initWithObject: (id)obj
{
	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFNoMemException
+ newWithObject: (id)obj
	andSize: (size_t)size
{
	return [[OFNoMemException alloc] initWithObject: obj
						andSize: size];
}

- initWithObject: (id)obj
	 andSize: (size_t)size
{
	fprintf(stderr, "ERROR: Could not allocate %zu bytes for object %s!\n",
	    size, [obj name]);

	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFNotImplementedException
+ newWithObject: (id)obj
      andMethod: (const char*)method
{
	return [[OFNotImplementedException alloc] initWithObject: obj
						       andMethod: method];
}

- initWithObject: (id)obj
       andMethod: (const char*)method
{
	fprintf(stderr, "ERROR: Requested method %s not implemented in %s!\n",
	    method, [obj name]);

	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFMemNotPartOfObjException
+ newWithObject: (id)obj
     andPointer: (void*)ptr
{
	return [[OFMemNotPartOfObjException alloc] initWithObject: obj
						       andPointer: ptr];
}

- initWithObject: (id)obj
      andPointer: (void*)ptr
{
	fprintf(stderr, "ERROR: Memory at %p was not allocated as part of "
	    "object %s!\n"
	    "ERROR: -> Not changing memory allocation!\n"
	    "ERROR: (Hint: It is possible that you tried to free the same "
	    "memory twice!)\n", ptr, [obj name]);

	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFOverflowException
+ newWithObject: (id)obj
{
	return [[OFOverflowException alloc] initWithObject: obj];
}

- initWithObject: (id)obj
{
	fprintf(stderr, "ERROR: Overflow in object %s!\n", [obj name]);

	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFOpenFileFailedException
+ newWithObject: (id)obj
	andPath: (const char*)path
	andMode: (const char*)mode
{
	return [[OFOpenFileFailedException alloc] initWithObject: obj
							 andPath: path
							 andMode: mode];
}

- initWithObject: (id)obj
	 andPath: (const char*)path
	 andMode: (const char*)mode
{
	fprintf(stderr, "ERROR: Failed to open file %s with mode %s in "
	    "object %s!\n", path, mode, [self name]);

	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFReadOrWriteFailedException
+ newWithObject: (id)obj
	andSize: (size_t)size
      andNItems: (size_t)nitems
{
	return [[OFReadOrWriteFailedException alloc] initWithObject: obj
							    andSize: size
							  andNItems: nitems];
}
@end

@implementation OFReadFailedException
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems
{
	fprintf(stderr, "ERROR: Failed to read %zu items of size %zu in "
	    "object %s!\n", nitems, size, [obj name]);

	self = [super init];
	@throw self;
	return self;
}
@end

@implementation OFWriteFailedException
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems
{
	fprintf(stderr, "ERROR: Failed to write %zu items of size %zu in "
	    "object %s!\n", nitems, size, [obj name]);

	self = [super init];
	@throw self;
	return self;
}
@end
