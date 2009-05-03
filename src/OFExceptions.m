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

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import <objc/objc-api.h>
#ifdef __objc_INCLUDE_GNU
#define SEL_NAME(x) sel_get_name(x)
#else
#import <objc/runtime.h>
#define SEL_NAME(x) sel_getName(x)
#endif

#import "OFExceptions.h"
#import "OFTCPSocket.h"

#ifndef _WIN32
#include <errno.h>
#define GET_ERR	     errno
#define GET_SOCK_ERR errno
#define ERRFMT	     "Error string was: %s"
#define ERRPARAM     strerror(err)
#else
#include <windows.h>
#define GET_ERR	     GetLastError()
#define GET_SOCK_ERR WSAGetLastError()
#define ERRFMT	     "Error code was: %d"
#define ERRPARAM     err
#endif

#ifndef HAVE_ASPRINTF
#import "asprintf.h"
#endif

@implementation OFAllocFailedException
+ (Class)class
{
	return self;
}

- (const char*)cString
{
	return "Allocating an object failed!";
}
@end

@implementation OFException
+ newWithClass: (Class)class_
{
	return [[self alloc] initWithClass: class_];
}

- initWithClass: (Class)class_
{
	self = [super init];

	class = class_;
	string = NULL;

	return self;
}

- free
{
	if (string != NULL)
		free(string);

	return [super free];
}

- (Class)inClass
{
	return class;
}

- (const char*)cString
{
	return string;
}
@end

@implementation OFNoMemException
+ newWithClass: (Class)class_
       andSize: (size_t)size
{
	return [[self alloc] initWithClass: class_
				   andSize: size];
}

- initWithClass: (Class)class_
	andSize: (size_t)size
{
	self = [super initWithClass: class_];

	req_size = size;

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Could not allocate %zu bytes in class %s!",
		req_size, [class name]);

	return string;
}

- (size_t)requestedSize
{
	return req_size;
}
@end

@implementation OFMemNotPartOfObjException
+ newWithClass: (Class)class_
    andPointer: (void*)ptr
{
	return [[self alloc] initWithClass: class_
				andPointer: ptr];
}

- initWithClass: (Class)class_
     andPointer: (void*)ptr
{
	self = [super initWithClass: class_];

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
	    "twice.", pointer, [class name]);

	return string;
}

- (void*)pointer
{
	return pointer;
}
@end

@implementation OFNotImplementedException
+ newWithClass: (Class)class_
   andSelector: (SEL)selector_
{
	return [[self alloc] initWithClass: class_
			       andSelector: selector_];
}

- initWithClass: (Class)class_
    andSelector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The method %s of class %s is not or not fully "
	    "implemented!", SEL_NAME(selector), [class name]);

	return string;
}
@end

@implementation OFOutOfRangeException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Value out of range in class %s!", [class name]);

	return string;
}
@end

@implementation OFInvalidArgumentException
+ newWithClass: (Class)class_
   andSelector: (SEL)selector_
{
	return [[self alloc] initWithClass: class_
			       andSelector: selector_];
}

- initWithClass: (Class)class_
    andSelector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The argument for method %s of class %s is invalid!",
	    SEL_NAME(selector), [class name]);

	return string;
}
@end

@implementation OFInvalidEncodingException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The encoding is invalid for class %s!",
	    [class name]);

	return string;
}
@end

@implementation OFInvalidFormatException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The format is invalid for class %s!", [class name]);

	return string;
}
@end

@implementation OFInitializationFailedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Initialization failed for class %s!", [class name]);

	return string;
}
@end

@implementation OFNotInSetException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The requested key is not in the set of type %s!",
	    [class name]);

	return string;
}
@end

@implementation OFOpenFileFailedException
+ newWithClass: (Class)class_
       andPath: (const char*)path_
       andMode: (const char*)mode_
{
	return [[self alloc] initWithClass: class_
				   andPath: path_
				   andMode: mode_];
}

- initWithClass: (Class)class_
	andPath: (const char*)path_
	andMode: (const char*)mode_
{
	self = [super initWithClass: class_];

	path = (path_ != NULL ? strdup(path_) : NULL);
	mode = (mode_ != NULL ? strdup(mode_) : NULL);
	err = GET_ERR;

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

	asprintf(&string, "Failed to open file %s with mode %s in class %s! "
	    ERRFMT, path, mode, [self name], ERRPARAM);

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
+ newWithClass: (Class)class_
       andSize: (size_t)size
     andNItems: (size_t)nitems
{
	return [[self alloc] initWithClass: class_
				   andSize: size
				 andNItems: nitems];
}

+ newWithClass: (Class)class_
       andSize: (size_t)size
{
	return [[self alloc] initWithClass: class_
				   andSize: size];
}

- initWithClass: (Class)class_
	andSize: (size_t)size
      andNItems: (size_t)nitems
{
	self = [super initWithClass: class_];

	req_size = size;
	req_items = nitems;
	has_items = YES;

	if (class_ == [OFTCPSocket class])
		err = GET_SOCK_ERR;
	else
		err = GET_ERR;

	return self;
}

- initWithClass: (Class)class_
	andSize: (size_t)size
{
	self = [super initWithClass: class_];

	req_size = size;
	req_items = 0;
	has_items = NO;

	if (class_ == [OFTCPSocket class])
		err = GET_SOCK_ERR;
	else
		err = GET_ERR;

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
		    "class %s! " ERRFMT, req_items, req_size, [class name],
		    ERRPARAM);
	else
		asprintf(&string, "Failed to read %zu bytes in class %s! "
		    ERRFMT, req_size, [class name], ERRPARAM);

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
		    "class %s! " ERRFMT, req_items, req_size, [class name],
		    ERRPARAM);
	else
		asprintf(&string, "Failed to write %zu bytes in class %s! "
		    ERRFMT, req_size, [class name], ERRFMT);

	return string;
}
@end

@implementation OFSetOptionFailedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Setting an option in class %s failed!",
	    [class name]);

	return string;
}
@end

@implementation OFNotConnectedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The socket of type %s is not connected or bound!",
	    [class name]);

	return string;
}
@end

@implementation OFAlreadyConnectedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The socket of type %s is already connected or bound "
	    "and thus can't be connected or bound again!", [class name]);

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
	    "invalid port.", [class name]);

	return string;
}
@end

@implementation OFAddressTranslationFailedException
+ newWithClass: (Class)class_
       andNode: (const char*)node_
    andService: (const char*)service_
{
	return [[self alloc] initWithClass: class_
				   andNode: node_
				andService: service_];
}

- initWithClass: (Class)class_
	andNode: (const char*)node_
     andService: (const char*)service_
{
	self = [super initWithClass: class_];

	node = (node_ != NULL ? strdup(node_) : NULL);
	service = (service_ != NULL ? strdup(service_) : NULL);
	err = GET_SOCK_ERR;

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
	    "address in class %s. This means that either the node was not "
	    "found, there is no such service on the node, there was a problem "
	    "with the name server, there was a problem with your network "
	    "connection or you specified an invalid node or service. " ERRFMT,
	    service, node, [class name], ERRPARAM);

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
+ newWithClass: (Class)class_
       andHost: (const char*)host_
       andPort: (uint16_t)port_
{
	return [[self alloc] initWithClass: class_
				   andHost: host_
				   andPort: port_];
}

- initWithClass: (Class)class_
	andHost: (const char*)host_
	andPort: (uint16_t)port_
{
	self = [super initWithClass: class_];

	host = (host_ != NULL ? strdup(host_) : NULL);
	port = port_;
	err = GET_SOCK_ERR;

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
	    "class %s! " ERRFMT, host, port, [class name], ERRPARAM);

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
+ newWithClass: (Class)class_
       andHost: (const char*)host_
       andPort: (uint16_t)port_
     andFamily: (int)family_
{
	return [[self alloc] initWithClass: class_
				   andHost: host_
				   andPort: port_
				 andFamily: family_];
}

- initWithClass: (Class)class_
	andHost: (const char*)host_
	andPort: (uint16_t)port_
      andFamily: (int)family_
{
	self = [super initWithClass: class_];

	host = (host_ != NULL ? strdup(host_) : NULL);
	port = port_;
	family = family_;
	err = GET_SOCK_ERR;

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
	    "class %s! " ERRFMT, port, host, family, [class name], ERRPARAM);

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
+ newWithClass: (Class)class_
    andBackLog: (int)backlog_
{
	return [[self alloc] initWithClass: class_
				andBackLog: backlog_];
}

- initWithClass: (Class)class_
     andBackLog: (int)backlog_
{
	self = [super initWithClass: class_];

	backlog = backlog_;
	err = GET_SOCK_ERR;

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Failed to listen in socket of type %s with a back "
	    "log of %d! "ERRFMT, [class name], backlog, ERRPARAM);

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
- initWithClass: (Class)class_
{
	self = [super initWithClass: class_];

	err = GET_SOCK_ERR;

	return self;
}

- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Failed to accept connection in socket of type %s! "
	    ERRFMT, [class name], ERRPARAM);

	return string;
}

- (int)errNo
{
	return err;
}
@end

@implementation OFThreadJoinFailedException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "Joining a thread of class %s failed! Most likely, "
	    "another thread already waits for the thread to join.",
	    [class name]);

	return string;
}
@end

@implementation OFThreadCanceledException
- (const char*)cString
{
	if (string != NULL)
		return string;

	asprintf(&string, "The requested action cannot be performed because "
	    "the thread of class %s was canceled!", [class name]);

	return string;
}
@end
