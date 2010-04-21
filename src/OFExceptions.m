/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef OF_APPLE_RUNTIME
# import <objc/runtime.h>
# import <objc/objc-api.h>
#endif

#ifdef OF_GNU_RUNTIME
# import <objc/objc-api.h>
# define sel_getName(x) sel_get_name(x)
#endif

#import "OFExceptions.h"
#import "OFString.h"
#import "OFTCPSocket.h"

#ifndef _WIN32
# include <errno.h>
# define GET_ERRNO	errno
# ifndef HAVE_THREADSAFE_GETADDRINFO
#  define GET_AT_ERRNO	h_errno
# else
#  define GET_AT_ERRNO	errno
# endif
# define GET_SOCK_ERRNO	errno
# define ERRFMT		"Error string was: %s"
# define ERRPARAM	strerror(errNo)
# ifndef HAVE_THREADSAFE_GETADDRINFO
#  define AT_ERRPARAM	hstrerror(errNo)
# else
#  define AT_ERRPARAM	strerror(errNo)
# endif
#else
# include <windows.h>
# define GET_ERRNO	GetLastError()
# define GET_AT_ERRNO	WSAGetLastError()
# define GET_SOCK_ERRNO	WSAGetLastError()
# define ERRFMT		"Error code was: %d"
# define ERRPARAM	errNo
# define AT_ERRPARAM	errNo
#endif

#import "asprintf.h"

@implementation OFAllocFailedException
+ (Class)class
{
	return self;
}

- (OFString*)string
{
	return @"Allocating an object failed!";
}
@end

@implementation OFException
+ newWithClass: (Class)class_
{
	return [[self alloc] initWithClass: class_];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
{
	self = [super init];

	class_ = class_;

	return self;
}

- (void)dealloc
{
	[string release];

	[super dealloc];
}

- (Class)inClass
{
	return inClass;
}

- (OFString*)string
{
	return string;
}

- autorelease
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end

@implementation OFOutOfMemoryException
+ newWithClass: (Class)class_
	  size: (size_t)size
{
	return [[self alloc] initWithClass: class_
				      size: size];
}

- initWithClass: (Class)class_
	   size: (size_t)size
{
	self = [super initWithClass: class_];

	requestedSize = size;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	if (requestedSize)
		string = [[OFString alloc] initWithFormat:
		    @"Could not allocate %zu bytes in class %s!", requestedSize,
		    [inClass className]];
	else
		string = [[OFString alloc] initWithFormat:
		    @"Could not allocate enough memory in class %s!",
		    [inClass className]];

	return string;
}

- (size_t)requestedSize
{
	return requestedSize;
}
@end

@implementation OFEnumerationMutationException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Object of class %s was mutated during enumeration!",
	    [inClass className]];

	return string;
}
@end

@implementation OFMemoryNotPartOfObjectException
+ newWithClass: (Class)class_
       pointer: (void*)ptr
{
	return [[self alloc] initWithClass: class_
				   pointer: ptr];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	pointer: (void*)ptr
{
	self = [super initWithClass: class_];

	pointer = ptr;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Memory at %p was not allocated as part of object of class %s, "
	    @"thus the memory allocation was not changed! It is also possible "
	    @"that there was an attempt to free the same memory twice.",
	    pointer, [inClass className]];

	return string;
}

- (void*)pointer
{
	return pointer;
}
@end

@implementation OFNotImplementedException
+ newWithClass: (Class)class_
      selector: (SEL)selector
{
	return [[self alloc] initWithClass: class_
				  selector: selector];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
       selector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The method %s of class %s is not or not fully implemented!",
	    sel_getName(selector), [inClass className]];

	return string;
}

- (SEL)selector
{
	return selector;
}
@end

@implementation OFOutOfRangeException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Value out of range in class %s!", [inClass className]];

	return string;
}
@end

@implementation OFInvalidArgumentException
+ newWithClass: (Class)class_
      selector: (SEL)selector_
{
	return [[self alloc] initWithClass: class_
				  selector: selector_];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
       selector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The argument for method %s of class %s is invalid!",
	    sel_getName(selector), [inClass className]];

	return string;
}

- (SEL)selector
{
	return selector;
}
@end

@implementation OFInvalidEncodingException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The encoding is invalid for class %s!", [inClass className]];

	return string;
}
@end

@implementation OFInvalidFormatException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The format is invalid for class %s!", [inClass className]];

	return string;
}
@end

@implementation OFMalformedXMLException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The parser in class %s encountered malformed or invalid XML!",
	    [inClass className]];

	return string;
}
@end

@implementation OFInitializationFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Initialization failed for class %s!", [inClass className]];

	return string;
}
@end

@implementation OFOpenFileFailedException
+ newWithClass: (Class)class_
	  path: (OFString*)path
	  mode: (OFString*)mode
{
	return [(OFOpenFileFailedException*)[self alloc] initWithClass: class_
								  path: path
								  mode: mode];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	   mode: (OFString*)mode_
{
	self = [super initWithClass: class_];

	path  = [path_ copy];
	mode  = [mode_ copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[path release];
	[mode release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to open file %s with mode %s in class %s! " ERRFMT,
	    [path cString], [mode cString], [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}

- (OFString*)mode
{
	return mode;
}
@end

@implementation OFReadOrWriteFailedException
+ newWithClass: (Class)class_
	  size: (size_t)size
{
	return [[self alloc] initWithClass: class_
				      size: size];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   size: (size_t)size
{
	self = [super initWithClass: class_];

	requestedSize = size;

	if ([class_ isSubclassOfClass: [OFSocket class]])
		errNo = GET_SOCK_ERRNO;
	else
		errNo = GET_ERRNO;

	return self;
}

- (int)errNo
{
	return errNo;
}

- (size_t)requestedSize
{
	return requestedSize;
}
@end

@implementation OFReadFailedException
- (OFString*)string
{
	if (string != nil)
		return string;;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to read %zu bytes in class %s! " ERRFMT, requestedSize,
	    [inClass className], ERRPARAM];

	return string;
}
@end

@implementation OFWriteFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to write %zu bytes in class %s! " ERRFMT, requestedSize,
	    [inClass className], ERRPARAM];

	return string;
}
@end

@implementation OFSeekFailedException
- initWithClass: (Class)class_
{
	self = [super initWithClass: class_];

	errNo = GET_ERRNO;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Seeking failed in class %s! " ERRFMT, [inClass className],
	    ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}
@end

@implementation OFCreateDirectoryFailedException
+ newWithClass: (Class)class_
	  path: (OFString*)path_
{
	return [[self alloc] initWithClass: class_
				      path: path_];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
{
	self = [super initWithClass: class_];

	path  = [path_ copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to create directory %s in class %s! " ERRFMT,
	    [path cString], [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}
@end

@implementation OFChangeFileModeFailedException
+ newWithClass: (Class)class_
	  path: (OFString*)path
	  mode: (mode_t)mode
{
	return [(OFChangeFileModeFailedException*)[self alloc]
	    initWithClass: class_
		     path: path
		     mode: mode];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	   mode: (mode_t)mode_
{
	self = [super initWithClass: class_];

	path  = [path_ copy];
	mode  = mode_;
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to change mode for file %s to %d in class %s! " ERRFMT,
	    [path cString], mode, [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}

- (mode_t)mode
{
	return mode;
}
@end

#ifndef _WIN32
@implementation OFChangeFileOwnerFailedException
+ newWithClass: (Class)class_
	  path: (OFString*)path
	 owner: (uid_t)owner
	 group: (gid_t)group
{
	return [[self alloc] initWithClass: class_
				      path: path
				     owner: owner
				     group: group];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	  owner: (uid_t)owner_
	  group: (gid_t)group_
{
	self = [super initWithClass: class_];

	path  = [path_ copy];
	owner = owner_;
	group = group_;
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to change owner for file %s to %d:%d in class %s! " ERRFMT,
	    [path cString], owner, group, [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}

- (uid_t)owner
{
	return owner;
}

- (gid_t)group
{
	return group;
}
@end
#endif

@implementation OFCopyFileFailedException
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	return [[self alloc] initWithClass: class_
				sourcePath: src
			   destinationPath: dst];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	self = [super initWithClass: class_];

	sourcePath = [src copy];
	destinationPath = [dst copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to copy file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)sourcePath
{
	return sourcePath;
}

- (OFString*)destinationPath;
{
	return destinationPath;
}
@end

@implementation OFRenameFileFailedException
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	return [[self alloc] initWithClass: class_
				sourcePath: src
			   destinationPath: dst];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	self = [super initWithClass: class_];

	sourcePath = [src copy];
	destinationPath = [dst copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to rename file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)sourcePath
{
	return sourcePath;
}

- (OFString*)destinationPath;
{
	return destinationPath;
}
@end

@implementation OFDeleteFileFailedException
+ newWithClass: (Class)class_
	  path: (OFString*)path_
{
	return [[self alloc] initWithClass: class_
				      path: path_];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
{
	self = [super initWithClass: class_];

	path  = [path_ copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to delete file %s in class %s! " ERRFMT, [path cString],
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}
@end

@implementation OFDeleteDirectoryFailedException
+ newWithClass: (Class)class_
	  path: (OFString*)path_
{
	return [[self alloc] initWithClass: class_
				      path: path_];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
{
	self = [super initWithClass: class_];

	path  = [path_ copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to delete directory %s in class %s! " ERRFMT,
	    [path cString], [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}
@end

#ifndef _WIN32
@implementation OFLinkFailedException
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest
{
	return [[self alloc] initWithClass: class_
				sourcePath: src
			   destinationPath: dest];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest
{
	self = [super initWithClass: class_];

	sourcePath = [src copy];
	destinationPath = [dest copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to link file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)sourcePath
{
	return sourcePath;
}

- (OFString*)destinationPath
{
	return destinationPath;
}
@end

@implementation OFSymlinkFailedException
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest
{
	return [[self alloc] initWithClass: class_
				sourcePath: src
			   destinationPath: dest];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest
{
	self = [super initWithClass: class_];

	sourcePath = [src copy];
	destinationPath = [dest copy];
	errNo = GET_ERRNO;

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to symlink file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)sourcePath
{
	return sourcePath;
}

- (OFString*)destinationPath
{
	return destinationPath;
}
@end
#endif

@implementation OFSetOptionFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Setting an option in class %s failed!", [inClass className]];

	return string;
}
@end

@implementation OFNotConnectedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The socket of type %s is not connected or bound!",
	    [inClass className]];

	return string;
}
@end

@implementation OFAlreadyConnectedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The socket of type %s is already connected or bound and thus "
	    @"can't be connected or bound again!", [inClass className]];

	return string;
}
@end

@implementation OFAddressTranslationFailedException
+ newWithClass: (Class)class_
	  node: (OFString*)node
       service: (OFString*)service
{
	return [[self alloc] initWithClass: class_
				      node: node
				   service: service];
}

- initWithClass: (Class)class_
{
	self = [super initWithClass: class_];

	errNo = GET_AT_ERRNO;

	return self;
}

- initWithClass: (Class)class_
	   node: (OFString*)node_
	service: (OFString*)service_
{
	self = [super initWithClass: class_];

	node	= [node_ copy];
	service = [service_ copy];
	errNo	= GET_AT_ERRNO;

	return self;
}

- (void)dealloc
{
	[node release];
	[service release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	if (node != nil && service != nil)
		string = [[OFString alloc] initWithFormat:
		    @"The service %s on %s could not be translated to an "
		    @"address in class %s. This means that either the node was "
		    @"not found, there is no such service on the node, there "
		    @"was a problem with the name server, there was a problem "
		    @"with your network connection or you specified an invalid "
		    @"node or service. " ERRFMT, [service cString],
		    [node cString], [inClass className], AT_ERRPARAM];
	else
		string = [[OFString alloc] initWithFormat:
		    @"An address translation failed in class %s! " ERRFMT,
		    [inClass className], AT_ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)node
{
	return node;
}

- (OFString*)service
{
	return service;
}
@end

@implementation OFConnectionFailedException
+ newWithClass: (Class)class_
	  node: (OFString*)node
       service: (OFString*)service
{
	return [[self alloc] initWithClass: class_
				      node: node
				   service: service];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   node: (OFString*)node_
	service: (OFString*)service_
{
	self = [super initWithClass: class_];

	node	= [node_ copy];
	service	= [service_ copy];
	errNo	= GET_SOCK_ERRNO;

	return self;
}

- (void)dealloc
{
	[node release];
	[service release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"A connection to service %s on node %s could not be established "
	    @"in class %s! " ERRFMT, [node cString], [service cString],
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)node
{
	return node;
}

- (OFString*)service
{
	return service;
}
@end

@implementation OFBindFailedException
+ newWithClass: (Class)class_
	  node: (OFString*)node
       service: (OFString*)service
	family: (int)family
{
	return [[self alloc] initWithClass: class_
				      node: node
				   service: service
				    family: family];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   node: (OFString*)node_
	service: (OFString*)service_
	 family: (int)family_
{
	self = [super initWithClass: class_];

	node	= [node_ copy];
	service	= [service_ copy];
	family	= family_;
	errNo	= GET_SOCK_ERRNO;

	return self;
}

- (void)dealloc
{
	[node release];
	[service release];

	[super dealloc];
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Binding service %s on node %s using family %d failed in class "
	    @"%s! " ERRFMT, [service cString], [node cString], family,
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)node
{
	return node;
}

- (OFString*)service
{
	return service;
}

- (int)family
{
	return family;
}
@end

@implementation OFListenFailedException
+ newWithClass: (Class)class_
       backLog: (int)backlog
{
	return [[self alloc] initWithClass: class_
				   backLog: backlog];
}

- initWithClass: (Class)class_
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithClass: (Class)class_
	backLog: (int)backlog
{
	self = [super initWithClass: class_];

	backLog = backlog;
	errNo = GET_SOCK_ERRNO;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to listen in socket of type %s with a back log of %d! "
	    ERRFMT, [inClass className], backLog, ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}

- (int)backLog
{
	return backLog;
}
@end

@implementation OFAcceptFailedException
- initWithClass: (Class)class_
{
	self = [super initWithClass: class_];

	errNo = GET_SOCK_ERRNO;

	return self;
}

- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Failed to accept connection in socket of type %s! " ERRFMT,
	    [inClass className], ERRPARAM];

	return string;
}

- (int)errNo
{
	return errNo;
}
@end

@implementation OFThreadStartFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Starting a thread of class %s failed!", [inClass className]];

	return string;
}
@end

@implementation OFThreadJoinFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Joining a thread of class %s failed! Most likely, another thread "
	    @"already waits for the thread to join.", [inClass className]];

	return string;
}
@end

@implementation OFThreadStillRunningException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"Deallocation of a thread of type %s was tried, even though it "
	    @"was still running", [inClass className]];

	return string;
}
@end

@implementation OFMutexLockFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"A mutex could not be locked in class %s", [inClass className]];

	return string;
}
@end

@implementation OFMutexUnlockFailedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"A mutex could not be unlocked in class %s", [inClass className]];

	return string;
}
@end

@implementation OFHashAlreadyCalculatedException
- (OFString*)string
{
	if (string != nil)
		return string;

	string = [[OFString alloc] initWithFormat:
	    @"The hash has already been calculated in class %s and thus no new "
	    @"data can be added", [inClass className]];

	return string;
}
@end
