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

#import <stdlib.h>
#import <string.h>

#import "OFString.h"
#import "OFConstCString.h"
#import "OFConstWideCString.h"
#import "OFCString.h"
#import "OFWideCString.h"
#import "OFExceptions.h"

@implementation OFString
+ newWithConstCString: (const char*)str
{
	return [[OFConstCString alloc] initWithConstCString: str];
}

+ newWithConstWideCString: (const wchar_t*)str
{
	return [[OFConstWideCString alloc] initWithConstWideCString: str];
}

+ newWithCString: (char*)str
{
	return [[OFCString alloc] initWithCString: str];
}

+ newWithWideCString: (wchar_t*)str
{
	return [[OFWideCString alloc] initWithWideCString: str];
}

- (char*)cString
{
	@throw [OFNotImplementedException new: self withMethod: "cString"];
	return NULL;
}

- (wchar_t*)wcString
{
	@throw [OFNotImplementedException new: self withMethod: "wcString"];
	return NULL;
}

- (size_t)length
{
	return length;
}

- (OFString*)setTo: (OFString*)str
{
	[self free];
	self = [str clone];
	return self;
}

- (OFString*)clone
{
	@throw [OFNotImplementedException new: self withMethod: "clone"];
	return nil;
}

- (int)compare: (OFString*)str
{
	@throw [OFNotImplementedException new: self withMethod: "compare:"];
	return 0;
}

- (OFString*)append: (OFString*)str
{
	@throw [OFNotImplementedException new: self withMethod: "append:"];
	return nil;
}
@end
