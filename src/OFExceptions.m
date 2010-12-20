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

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
# import <objc/runtime.h>
#endif

#ifdef OF_OLD_GNU_RUNTIME
# import <objc/objc-api.h>
# define sel_getName(x) sel_get_name(x)
# define class_getName class_get_class_name
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
+ alloc
{
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)addMemoryToPool: (void*)ptr
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void*)allocMemoryWithSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void*)allocMemoryForNItems: (size_t)nitems
                     withSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
	       toSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void*)resizeMemory: (void*)ptr
	     toNItems: (size_t)nitems
	     withSize: (size_t)size
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)freeMemory: (void*)ptr
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (size_t)retainCount
{
	return SIZE_MAX;
}

- (void)release
{
}

- (void)dealloc
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}

- (OFString*)description
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
{
	self = [super init];

	inClass = class_;

	return self;
}

- (void)dealloc
{
	[description release];

	[super dealloc];
}

- (Class)inClass
{
	return inClass;
}

- (OFString*)description
{
	return @"An exception occurred";
}

- autorelease
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end

@implementation OFOutOfMemoryException
+  newWithClass: (Class)class_
  requestedSize: (size_t)size
{
	return [[self alloc] initWithClass: class_
			     requestedSize: size];
}

- initWithClass: (Class)class_
  requestedSize: (size_t)size
{
	self = [super initWithClass: class_];

	requestedSize = size;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (requestedSize)
		description = [[OFString alloc] initWithFormat:
		    @"Could not allocate %zu bytes in class %s!", requestedSize,
		    class_getName(inClass)];
	else
		description = [[OFString alloc] initWithFormat:
		    @"Could not allocate enough memory in class %s!",
		    class_getName(inClass)];

	return description;
}

- (size_t)requestedSize
{
	return requestedSize;
}
@end

@implementation OFEnumerationMutationException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Object of class %s was mutated during enumeration!",
	    class_getName(inClass)];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	pointer: (void*)ptr
{
	self = [super initWithClass: class_];

	pointer = ptr;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Memory at %p was not allocated as part of object of class %s, "
	    @"thus the memory allocation was not changed! It is also possible "
	    @"that there was an attempt to free the same memory twice.",
	    pointer, class_getName(inClass)];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
       selector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The method %s of class %s is not or not fully implemented!",
	    sel_getName(selector), class_getName(inClass)];

	return description;
}

- (SEL)selector
{
	return selector;
}
@end

@implementation OFOutOfRangeException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Value out of range in class %s!", class_getName(inClass)];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
       selector: (SEL)selector_
{
	self = [super initWithClass: class_];

	selector = selector_;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The argument for method %s of class %s is invalid!",
	    sel_getName(selector), class_getName(inClass)];

	return description;
}

- (SEL)selector
{
	return selector;
}
@end

@implementation OFInvalidEncodingException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The encoding is invalid for class %s!", class_getName(inClass)];

	return description;
}
@end

@implementation OFInvalidFormatException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The format is invalid for class %s!", class_getName(inClass)];

	return description;
}
@end

@implementation OFMalformedXMLException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The parser in class %s encountered malformed or invalid XML!",
	    class_getName(inClass)];

	return description;
}
@end

@implementation OFInitializationFailedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Initialization failed for class %s!", class_getName(inClass)];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	   mode: (OFString*)mode_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		mode  = [mode_ copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];
	[mode release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to open file %s with mode %s in class %s! " ERRFMT,
	    [path cString], [mode cString], class_getName(inClass), ERRPARAM];

	return description;
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
+  newWithClass: (Class)class_
  requestedSize: (size_t)size
{
	return [[self alloc] initWithClass: class_
			     requestedSize: size];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
  requestedSize: (size_t)size
{
	self = [super initWithClass: class_];

	requestedSize = size;

	if ([class_ isSubclassOfClass: [OFStreamSocket class]])
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
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to read %zu bytes in class %s! " ERRFMT, requestedSize,
	    class_getName(inClass), ERRPARAM];

	return description;
}
@end

@implementation OFWriteFailedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to write %zu bytes in class %s! " ERRFMT, requestedSize,
	    class_getName(inClass), ERRPARAM];

	return description;
}
@end

@implementation OFSeekFailedException
- initWithClass: (Class)class_
{
	self = [super initWithClass: class_];

	errNo = GET_ERRNO;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Seeking failed in class %s! " ERRFMT, class_getName(inClass),
	    ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to create directory %s in class %s! " ERRFMT,
	    [path cString], class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	   mode: (mode_t)mode_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		mode  = mode_;
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to change mode for file %s to %d in class %s! " ERRFMT,
	    [path cString], mode, class_getName(inClass), ERRPARAM];

	return description;
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
	 owner: (OFString*)owner
	 group: (OFString*)group
{
	return [[self alloc] initWithClass: class_
				      path: path
				     owner: owner
				     group: group];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
	  owner: (OFString*)owner_
	  group: (OFString*)group_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		owner = [owner_ copy];
		group = [group_ copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];
	[owner release];
	[group release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (group == nil)
		description = [[OFString alloc] initWithFormat:
		    @"Failed to change owner for file %s to %s in class %s! "
		    ERRFMT, [path cString], [owner cString],
		    class_getName(inClass), ERRPARAM];
	else if (owner == nil)
		description = [[OFString alloc] initWithFormat:
		    @"Failed to change group for file %s to %s in class %s! "
		    ERRFMT, [path cString], [group cString],
		    class_getName(inClass), ERRPARAM];
	else
		description = [[OFString alloc] initWithFormat:
		    @"Failed to change owner for file %s to %s:%s in class %s! "
		    ERRFMT, [path cString], [owner cString], [group cString],
		    class_getName(inClass), ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}

- (OFString*)path
{
	return path;
}

- (OFString*)owner
{
	return owner;
}

- (OFString*)group
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	self = [super initWithClass: class_];

	@try {
		sourcePath = [src copy];
		destinationPath = [dst copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to copy file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst
{
	self = [super initWithClass: class_];

	@try {
		sourcePath = [src copy];
		destinationPath = [dst copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to rename file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to delete file %s in class %s! " ERRFMT, [path cString],
	    class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   path: (OFString*)path_
{
	self = [super initWithClass: class_];

	@try {
		path  = [path_ copy];
		errNo = GET_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[path release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to delete directory %s in class %s! " ERRFMT,
	    [path cString], class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
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

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to link file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
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

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to symlink file %s to %s in class %s! " ERRFMT,
	    [sourcePath cString], [destinationPath cString],
	    class_getName(inClass), ERRPARAM];

	return description;
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
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Setting an option in class %s failed!", class_getName(inClass)];

	return description;
}
@end

@implementation OFNotConnectedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The socket of type %s is not connected or bound!",
	    class_getName(inClass)];

	return description;
}
@end

@implementation OFAlreadyConnectedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The socket of type %s is already connected or bound and thus "
	    @"can't be connected or bound again!", class_getName(inClass)];

	return description;
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

	@try {
		node	= [node_ copy];
		service = [service_ copy];
		errNo	= GET_AT_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[node release];
	[service release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (node != nil && service != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The service %s on %s could not be translated to an "
		    @"address in class %s. This means that either the node was "
		    @"not found, there is no such service on the node, there "
		    @"was a problem with the name server, there was a problem "
		    @"with your network connection or you specified an invalid "
		    @"node or service. " ERRFMT, [service cString],
		    [node cString], class_getName(inClass), AT_ERRPARAM];
	else
		description = [[OFString alloc] initWithFormat:
		    @"An address translation failed in class %s! " ERRFMT,
		    class_getName(inClass), AT_ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   node: (OFString*)node_
	service: (OFString*)service_
{
	self = [super initWithClass: class_];

	@try {
		node	= [node_ copy];
		service	= [service_ copy];
		errNo	= GET_SOCK_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[node release];
	[service release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"A connection to service %s on node %s could not be established "
	    @"in class %s! " ERRFMT, [service cString], [node cString],
	    class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
	   node: (OFString*)node_
	service: (OFString*)service_
	 family: (int)family_
{
	self = [super initWithClass: class_];

	@try {
		node	= [node_ copy];
		service	= [service_ copy];
		family	= family_;
		errNo	= GET_SOCK_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[node release];
	[service release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Binding service %s on node %s using family %d failed in class "
	    @"%s! " ERRFMT, [service cString], [node cString], family,
	    class_getName(inClass), ERRPARAM];

	return description;
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
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

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to listen in socket of type %s with a back log of %d! "
	    ERRFMT, class_getName(inClass), backLog, ERRPARAM];

	return description;
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

- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Failed to accept connection in socket of type %s! " ERRFMT,
	    class_getName(inClass), ERRPARAM];

	return description;
}

- (int)errNo
{
	return errNo;
}
@end

@implementation OFThreadStartFailedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Starting a thread of class %s failed!", class_getName(inClass)];

	return description;
}
@end

@implementation OFThreadJoinFailedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Joining a thread of class %s failed! Most likely, another thread "
	    @"already waits for the thread to join.", class_getName(inClass)];

	return description;
}
@end

@implementation OFThreadStillRunningException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"Deallocation of a thread of type %s was tried, even though it "
	    @"was still running", class_getName(inClass)];

	return description;
}
@end

@implementation OFMutexLockFailedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"A mutex could not be locked in class %s", class_getName(inClass)];

	return description;
}
@end

@implementation OFMutexUnlockFailedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"A mutex could not be unlocked in class %s",
	    class_getName(inClass)];

	return description;
}
@end

@implementation OFHashAlreadyCalculatedException
- (OFString*)description
{
	if (description != nil)
		return description;

	description = [[OFString alloc] initWithFormat:
	    @"The hash has already been calculated in class %s and thus no new "
	    @"data can be added", class_getName(inClass)];

	return description;
}
@end

@implementation OFUnboundNamespaceException
+ newWithClass: (Class)class_
     namespace: (OFString*)ns
{
	return [[self alloc] initWithClass: class_
				 namespace: ns];
}

+ newWithClass: (Class)class_
	prefix: (OFString*)prefix
{
	return [[self alloc] initWithClass: class_
				    prefix: prefix];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
      namespace: (OFString*)ns_
{
	self = [super initWithClass: class_];

	@try {
		ns = [ns_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithClass: (Class)class_
	 prefix: (OFString*)prefix_
{
	self = [super initWithClass: class_];

	@try {
		prefix = [prefix_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[ns release];
	[prefix release];

	[super dealloc];
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (ns != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The namespace %s is not bound in class %s",
		    class_getName(inClass)];
	else if (prefix != nil)
		description = [[OFString alloc] initWithFormat:
		    @"The prefix %s is not bound to any namespace in %s",
		    class_getName(inClass)];

	return description;
}

- (OFString*)namespace
{
	return ns;
}

- (OFString*)prefix
{
	return prefix;
}
@end
