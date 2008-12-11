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
	return [[self alloc] initWithObject: obj];
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

- (id)object
{
	return object;
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
	return [[self alloc] initWithObject: obj
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

	asprintf(&string, "Could not allocate %zu bytes for object of class "
	    "%s!", req_size, object != nil ? [object name] : "(null)");

	return string;
}

- (size_t)requestedSize
{
	return req_size;
}
@end

@implementation OFMemNotPartOfObjException
+ newWithObject: (id)obj
     andPointer: (void*)ptr
{
	return [[self alloc] initWithObject: obj
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

	asprintf(&string, "Memory at %p was not allocated as part of object "
	    "of class %s, thus the memory allocation was not changed! It is "
	    "also possible that there was an attempt to free the same memory "
	    "twice.", pointer, [object name]);

	return string;
}

- (void*)pointer
{
	return pointer;
}
@end

@implementation OFOutOfRangeException
- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Value out of range in object of class %s!",
	    object != nil ? [object name] : "(null)");

	return string;
}
@end

@implementation OFCharsetConversionFailedException
- (char*)cString
{
	if (string != NULL)
		return string;
	
	asprintf(&string, "Charset conversion failed in object of classs %s!",
	    [object name]);

	return string;
}
@end

@implementation OFOpenFileFailedException
+ newWithObject: (id)obj
	andPath: (const char*)p
	andMode: (const char*)m
{
	return [[self alloc] initWithObject: obj
				    andPath: p
				    andMode: m];
}

- initWithObject: (id)obj
	 andPath: (const char*)p
	 andMode: (const char*)m
{
	if ((self = [super initWithObject: obj])) {
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

	asprintf(&string, "Failed to open file %s with mode %s in object of "
	    "class %s!", path, mode, [self name]);

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
	return [[self alloc] initWithObject: obj
				    andSize: size
				  andNItems: nitems];
}

+ newWithObject: (id)obj
	andSize: (size_t)size
{
	return [[self alloc] initWithObject: obj
				    andSize: size];
}

- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems
{
	if ((self = [super initWithObject: obj])) {
		req_size = size;
		req_items = nitems;
		has_items = YES;
	}

	return self;
}

- initWithObject: (id)obj
	 andSize: (size_t)size
{
	if ((self = [super initWithObject: obj])) {
		req_size = size;
		req_items = 0;
		has_items = NO;
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

	if (has_items)
		asprintf(&string, "Failed to read %zu items of size %zu in "
		    "object of class %s!", req_items, req_size, [object name]);
	else
		asprintf(&string, "Failed to read %zu bytes in object of class "
		    "%s!", req_size, [object name]);

	return string;
}
@end

@implementation OFWriteFailedException
- (char*)cString
{
	if (string != NULL)
		return string;

	if (has_items)
		asprintf(&string, "Failed to write %zu items of size %zu in "
		    "object of class %s!", req_items, req_size, [object name]);
	else
		asprintf(&string, "Failed to write %zu bytes in object of "
		    "class %s!", req_size, [object name]);

	return string;
}
@end

@implementation OFNotConnectedException
- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The socket of type %s is not connected or bound!",
	    [object name]);

	return string;
}
@end

@implementation OFAlreadyConnectedException
- (char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The socket of type %s is already connected or bound "
	    "and thus can't be connected or bound again!", [object name]);

	return string;
}
@end
