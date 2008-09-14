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
#import <wchar.h>
#import "OFObject.h"

@interface OFWideString: OFObject
{
	wchar_t	*wstring;
	size_t	length;
}

+ new:(const wchar_t*)wstr;
- init;
- init:(const wchar_t*)wstr;
- (wchar_t*)wcString;
- (size_t)length;
- (OFWideString*)setTo:(const wchar_t*)wstr;
- (OFWideString*)clone;
- (OFWideString*)append:(const wchar_t*)wstr;
@end

/* vim: se syn=objc: */
