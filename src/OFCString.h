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

#import <stddef.h>

#import "OFObject.h"
#import "OFString.h"

@interface OFCString: OFString
{
	char   *string;
	size_t length;
}

- initWithCString: (char*)str;
- (char*)cString;
- (size_t)length;
- (OFString*)clone;
- (int)compareTo: (OFString*)str;
- (OFString*)append: (OFString*)str;
- (OFString*)appendCString: (const char*)str;
@end
