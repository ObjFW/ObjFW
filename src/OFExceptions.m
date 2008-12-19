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
#import <errno.h>

#import "OFExceptions.h"

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
	andPath: (const char*)path_
	andMode: (const char*)mode_
{
	return [[self alloc] initWithObject: obj
				    andPath: path_
				    andMode: mode_];
}

- initWithObject: (id)obj
	 andPath: (const char*)path_
	 andMode: (const char*)mode_
{
	if ((self = [super initWithObject: obj])) {
		path = (path_ != NULL ? strdup(path_) : NULL);
		mode = (mode_ != NULL ? strdup(mode_) : NULL);
		err = errno;
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
	    "class %s! Error string was: %s", path, mode, [self name],
	    strerror(err));

	return string;
}

- (int)errNo
{
	return err;
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
		err = errno;
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
		err = errno;
	}

	return self;
}

- (int)errNo
{
	return err;
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
		    "object of class %s! Error string was: %s", req_items,
		    req_size, [object name], strerror(err));
	else
		asprintf(&string, "Failed to read %zu bytes in object of class "
		    "%s! Error string was: %s", req_size, [object name],
		    strerror(err));

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
		    "object of class %s! Error string was: %s", req_items,
		    req_size, [object name], strerror(err));
	else
		asprintf(&string, "Failed to write %zu bytes in object of "
		    "class %s! Error string was: %s", req_size, [object name],
		    strerror(err));

	return string;
}
@end

@implementation OFSetOptionFailedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Setting an option for an object of type type %s "
	    "failed!", [object name]);

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
	andNode: (const char*)node_
     andService: (const char*)service_
{
	return [self newWithObject: obj
			   andNode: node_
			andService: service_];
}

- initWithObject: (id)obj
	 andNode: (const char*)node_
      andService: (const char*)service_
{
	if ((self = [super initWithObject: obj])) {
		node = (node_ != NULL ? strdup(node_) : NULL);
		service = (service_ != NULL ? strdup(service_) : NULL);
		err = errno;
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
	    "network connection or you specified an invalid node or service. "
	    "Error string was: %s", service, node, [object name],
	    strerror(err));

	return string;
}

- (int)errNo
{
	return err;
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
	andHost: (const char*)host_
	andPort: (uint16_t)port_
{
	return [self newWithObject: obj
			   andHost: host_
			   andPort: port_];
}

- initWithObject: (id)obj
	 andHost: (const char*)host_
	 andPort: (uint16_t)port_
{
	if ((self = [super initWithObject: obj])) {
		host = (host_ != NULL ? strdup(host_) : NULL);
		port = port_;
		err = errno;
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
	    "object of type %s! Error string was: %s", host, port,
	    [object name], strerror(err));

	return string;
}

- (int)errNo
{
	return err;
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
	andHost: (const char*)host_
	andPort: (uint16_t)port_
      andFamily: (int)family_
{
	return [self newWithObject: obj
			   andHost: host_
			   andPort: port_
			 andFamily: family_];
}

- initWithObject: (id)obj
	 andHost: (const char*)host_
	 andPort: (uint16_t)port_
       andFamily: (int)family_
{
	if ((self = [super initWithObject: obj])) {
		host = (host_ != NULL ? strdup(host_) : NULL);
		port = port_;
		family = family_;
		err = errno;
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
	    "object of type %s! Error string was: %s", port, host, family,
	    [object name], strerror(err));

	return string;
}

- (int)errNo
{
	return err;
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

@implementation OFListenFailedException
+ newWithObject: (id)obj
     andBackLog: (int)backlog_
{
	return [[self alloc] initWithObject: obj
				 andBackLog: backlog_];
}

- initWithObject: (id)obj
      andBackLog: (int)backlog_
{
	if ((self = [super initWithObject: obj])) {
		backlog = backlog_;
		err = errno;
	}

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Failed to listen in socket of type %s with a back "
	    "log of %d! Error string was: %s", [object name], backlog,
	    strerror(err));

	return string;
}

- (int)errNo
{
	return err;
}

- (int)backLog
{
	return backlog;
}
@end

@implementation OFAcceptFailedException
- initWithObject: (id)obj
{
	if ((self = [super initWithObject: obj]))
		err = errno;

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Failed to accept connection in socket of type %s! "
	    "Error string was: %s", [object name], strerror(err));

	return string;
}

- (int)errNo
{
	return err;
}
@end
