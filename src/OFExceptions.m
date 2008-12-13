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

#ifndef HAVE_ASPRINTF
#import "asprintf.h"
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

- (const char*)cString
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

- (const char*)cString
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

- (const char*)cString
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
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Value out of range in object of class %s!",
	    object != nil ? [object name] : "(null)");

	return string;
}
@end

@implementation OFCharsetConversionFailedException
- (const char*)cString
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
		path = (p != NULL ? strdup(p) : NULL);
		mode = (m != NULL ? strdup(m) : NULL);
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

- (const char*)cString
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

- (BOOL)hasNItems
{
	return has_items;
}
@end

@implementation OFReadFailedException
- (const char*)cString
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
- (const char*)cString
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
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The socket of type %s is not connected or bound!",
	    [object name]);

	return string;
}
@end

@implementation OFAlreadyConnectedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The socket of type %s is already connected or bound "
	    "and thus can't be connected or bound again!", [object name]);

	return string;
}
@end

@implementation OFInvalidPortException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The port specified is not valid for a socket of "
	    "type %s! This usually means you tried to use port 0, which is an "
	    "invalid port.", [object name]);

	return string;
}
@end

@implementation OFAddressTranslationFailedException
+ newWithObject: (id)obj
	andNode: (const char*)n
     andService: (const char*)s
{
	return [self newWithObject: obj
			   andNode: n
			andService: s];
}

- initWithObject: (id)obj
	 andNode: (const char*)n
      andService: (const char*)s
{
	if ((self = [super initWithObject: obj])) {
		node = (n != NULL ? strdup(n) : NULL);
		service = (s != NULL ? strdup(s) : NULL);
	}

	return self;
}

- free
{
	if (node != NULL)
		free(node);
	if (service != NULL)
		free(node);

	return [super free];
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The service %s on %s could not be translated to an "
	    "address for an object of type %s. This means that either the node "
	    "was not found, there is no such service on the node, there was a "
	    "problem with the name server, there was a problem with your "
	    "network connection or you specified an invalid node or service.",
	    service, node, [object name]);

	return string;
}

- (const char*)node
{
	return node;
}

- (const char*)service
{
	return service;
}
@end

@implementation OFConnectionFailedException
+ newWithObject: (id)obj
	andHost: (const char*)h
	andPort: (uint16_t)p
{
	return [self newWithObject: obj
			   andHost: h
			   andPort: p];
}

- initWithObject: (id)obj
	 andHost: (const char*)h
	 andPort: (uint16_t)p
{
	if ((self = [super initWithObject: obj])) {
		host = (h != NULL ? strdup(h) : NULL);
		port = p;
	}

	return self;
}

- free
{
	if (host != NULL)
		free(host);

	return [super free];
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "A connection to %s:%d could not be established in "
	    "object of type %s!", host, port, [object name]);

	return string;
}

- (const char*)host
{
	return host;
}

- (uint16_t)port
{
	return port;
}
@end

@implementation OFBindFailedException
+ newWithObject: (id)obj
	andHost: (const char*)h
	andPort: (uint16_t)p
      andFamily: (int)f
{
	return [self newWithObject: obj
			   andHost: h
			   andPort: p
			 andFamily: f];
}

- initWithObject: (id)obj
	 andHost: (const char*)h
	 andPort: (uint16_t)p
       andFamily: (int)f
{
	if ((self = [super initWithObject: obj])) {
		host = (h != NULL ? strdup(h) : NULL);
		port = p;
		family = f;
	}

	return self;
}

- free
{
	if (host != NULL)
		free(host);

	return [super free];
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Binding to port %d on %s using family %d failed in "
	    "object of type %s!", port, host, family, [object name]);

	return string;
}

- (const char*)host
{
	return host;
}

- (uint16_t)port
{
	return port;
}

- (int)family
{
	return family;
}
@end
