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
#import <stdlib.h>

#import "OFExceptions.h"

@implementation OFException
+ newWithObject: (id)obj
{
	return [[OFException alloc] initWithObject: obj];
}

- initWithObject: (id)obj
{
	if ((self = [super init]))
		errstr = NULL;

	return self;
}

- free
{
	if (errstr != NULL)
		free(errstr);

	return [super free];
}

- (void)raise
{
	@throw self;
}

- (char*)string
{
	return errstr;
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
	if ((self = [super init]))
		asprintf(&errstr, "ERROR: Could not allocate %zu bytes for "
		    "object of class %s!\n", size, [obj name]);

	return self;
}
@end

@implementation OFNotImplementedException
+ newWithObject: (id)obj
    andSelector: (SEL)sel
{
	return [[OFNotImplementedException alloc] initWithObject: obj
						     andSelector: sel];
}

- initWithObject: (id)obj
     andSelector: (SEL)sel
{
	if ((self = [super init]))
		/* FIXME: Is casting SEL to char* portable? */
		asprintf(&errstr, "ERROR: Requested selector %s not "
		    "implemented in %s!\n", (char*)sel, [obj name]);

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
	if ((self = [super init]))
		asprintf(&errstr, "ERROR: Memory at %p was not allocated as "
		    "part of object of class\n"
		    "ERROR: %s!\n"
		    "ERROR: -> Not changing memory allocation!\n"
		    "ERROR: (Hint: It is possible that you tried to free the "
		    "same memory twice!)\n", ptr, [obj name]);

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
	if ((self = [super init]))
		asprintf(&errstr, "ERROR: Overflow in object of class %s!\n",
		    [obj name]);

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
	if ((self = [super init]))
		asprintf(&errstr, "ERROR: Failed to open file %s with mode %s "
		    "in object of class %s!\n", path, mode, [self name]);

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
	if ((self = [super init]))
		asprintf(&errstr, "ERROR: Failed to read %zu items of size "
		    "%zu in object of class %s!\n", nitems, size, [obj name]);

	return self;
}
@end

@implementation OFWriteFailedException
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems
{
	if ((self = [super init]))
		asprintf(&errstr, "ERROR: Failed to write %zu items of size "
		    "%zu in object of class %s!\n", nitems, size, [obj name]);

	return self;
}
@end
