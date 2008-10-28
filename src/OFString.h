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

#import <wchar.h>
#import <stddef.h>

#import "OFObject.h"

@interface OFString: OFObject
+ newAsConstCString: (const char*)str;
+ newAsConstWideCString: (const wchar_t*)str;
+ newAsCString: (char*)str;
+ newAsWideCString: (wchar_t*)str;

- (char*)cString;
- (wchar_t*)wcString;
- (size_t)length;
- (OFString*)setTo: (OFString*)str;
- (OFString*)clone;
- (int)compareTo: (OFString*)str;
- (OFString*)append: (OFString*)str;
- (OFString*)appendCString: (const char*)str;
- (OFString*)appendWideCString: (const wchar_t*)str;
@end
