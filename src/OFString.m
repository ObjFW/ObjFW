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

#import <stdlib.h>
#import <string.h>

#import "OFString.h"
#import "OFConstCString.h"
#import "OFConstWideCString.h"
#import "OFCString.h"
#import "OFWideCString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

@implementation OFString
+ newAsConstCString: (const char*)str
{
	return [[OFConstCString alloc] initAsConstCString: str];
}

+ newAsConstWideCString: (const wchar_t*)str
{
	return [[OFConstWideCString alloc] initAsConstWideCString: str];
}

+ newAsCString: (char*)str
{
	return [[OFCString alloc] initAsCString: str];
}

+ newAsWideCString: (wchar_t*)str
{
	return [[OFWideCString alloc] initAsWideCString: str];
}

- (char*)cString
{
	OF_NOT_IMPLEMENTED(NULL)
}

- (wchar_t*)wcString
{
	OF_NOT_IMPLEMENTED(NULL)
}

- (size_t)length
{
	OF_NOT_IMPLEMENTED(0)
}

- (OFString*)setTo: (OFString*)str
{
	[self free];
	self = [str clone];
	return self;
}

- (OFString*)clone
{
	OF_NOT_IMPLEMENTED(nil)
}

- (int)compareTo: (OFString*)str
{
	OF_NOT_IMPLEMENTED(0)
}

- (OFString*)append: (OFString*)str
{
	OF_NOT_IMPLEMENTED(nil)
}

- (OFString*)appendCString: (const char*)str
{
	OF_NOT_IMPLEMENTED(nil)
}

- (OFString*)appendWideCString: (const wchar_t*)str
{
	OF_NOT_IMPLEMENTED(nil)
}
@end
