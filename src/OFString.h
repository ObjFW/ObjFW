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
#import "OFConstString.h"

@interface OFString: OFObject
{
	char   *string;
	size_t length;
}

+ new: (const char*)str;
- init;
- init: (const char*)str;
- (char*)cString;
- (size_t)length;
- (OFString*)setTo: (OFConstString*)str;
- (OFString*)clone;
- (OFString*)append: (OFConstString*)str;
- (int)compare: (OFConstString*)str;
@end
