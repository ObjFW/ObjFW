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

#import "config.h"

#define _GNU_SOURCE
#import <stdio.h>
#import <stdlib.h>
#import <string.h>

#import <objc/objc-api.h>

#import "OFExceptions.h"

#if defined HAVE_SEL_GET_NAME
#define SEL_NAME(x) sel_get_name(x)
#elif defined HAVE_SEL_GETNAME
#define SEL_NAME(x) sel_getName(x)
#else
#error "You need either sel_get_name() or sel_getName!"
#endif

@implementation OFException
+ newWithObject: (id)obj
{
	return [[OFException alloc] initWithObject: obj];
}

- initWithObject: (id)obj
{
	if ((self = [super init])) {
		object = obj;
		string = NULL;
	}

	return self;
}

- free
{
	if (string != NULL)
		free(string);

	return [super free];
}

- raise
{
	@throw self;
	return self;
}

- (char*)cString
{
	return string;
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
	if ((self = [super initWithObject: obj]))
		req_size = size;

	return self;
}

- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "ERROR: Could not allocate %zu bytes for object of"
	    "class %s!\n", req_size, object != nil ? [object name] : "(null)");

	return string;
}

- (size_t)requestedSize
{
	return req_size;
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
	if ((self = [super initWithObject: obj]))
		selector = sel;

	return self;
}

- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "ERROR: Requested selector %s not implemented in "
	    "%s!\n", SEL_NAME(selector), [object name]);

	return string;
}

- (SEL)selector
{
	return selector;
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
	if ((self = [super initWithObject: obj]))
		pointer = ptr;

	return self;
}

- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "ERROR: Memory at %p was not allocated as part of "
	    "object of class\n"
	    "ERROR: %s!\n"
	    "ERROR: -> Not changing memory allocation!\n"
	    "ERROR: (Hint: It is also possible that you tried to free the same "
	    "memory twice!)\n", pointer, [object name]);

	return string;
}

- (void*)pointer
{
	return pointer;
}
@end

@implementation OFOverflowException
+ newWithObject: (id)obj
{
	return [[OFOverflowException alloc] initWithObject: obj];
}

- initWithObject: (id)obj
{
	return (self = [super initWithObject: obj]);
}

- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "ERROR: Overflow in object of class %s!\n",
	    object != nil ? [object name] : "(null)");

	return string;
}
@end

@implementation OFOpenFileFailedException
+ newWithObject: (id)obj
	andPath: (const char*)p
	andMode: (const char*)m
{
	return [[OFOpenFileFailedException alloc] initWithObject: obj
							 andPath: p
							 andMode: m];
}

- initWithObject: (id)obj
	 andPath: (const char*)p
	 andMode: (const char*)m
{
	if ((self = [super init])) {
		path = p != NULL ? strdup(p) : NULL;
		mode = m != NULL ? strdup(m) : NULL;
	}

	return self;
}

- free
{
	if (path != NULL)
		free(path);
	if (mode != NULL)
		free(mode);

	return [super free];
}

- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "ERROR: Failed to open file %s with mode %s "
	    "in object of class %s!\n", path, mode, [self name]);

	return string;
}

- (char*)path
{
	return path;
}

- (char*)mode
{
	return mode;
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

- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems
{
	if ((self = [super init])) {
		req_size = size;
		req_items = nitems;
	}

	return self;
}

- (size_t)requestedSize
{
	return req_size;
}

- (size_t)requestedItems
{
	return req_items;
}
@end

@implementation OFReadFailedException
- (char*)cString
{
	if (string != NULL)
		return string;;

	asprintf(&string, "ERROR: Failed to read %zu items of size %zu in "
	    "object of class %s!\n", req_items, req_size, [object name]);

	return string;
}
@end

@implementation OFWriteFailedException
- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "ERROR: Failed to write %zu items of size %zu in "
	    "object of class %s!\n", req_items, req_size, [object name]);

	return string;
}
@end
