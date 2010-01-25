/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFConstString.h"
#import "OFExceptions.h"

#ifdef OF_APPLE_RUNTIME
#import <objc/runtime.h>

void *_OFConstStringClassReference;
#endif

@implementation OFConstString
#ifdef OF_APPLE_RUNTIME
+ (void)load
{
	objc_setFutureClass((Class)&_OFConstStringClassReference,
	    "OFConstString");
}
#endif

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

- initWithCString: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithCString: (const char*)str
	 encoding: (enum of_string_encoding)encoding;
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithCString: (const char*)str
	 encoding: (enum of_string_encoding)encoding
	   length: (size_t)len
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithCString: (const char*)str
           length: (size_t)len
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithFormat: (OFString*)fmt, ...
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithFormat: (OFString*)fmt
       arguments: (va_list)args
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithString: (OFString*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- addMemoryToPool: (void*)ptr
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

- freeMemory: (void*)ptr
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

- (uint32_t)retainCount
{
	return UINT32_MAX;
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
@end
