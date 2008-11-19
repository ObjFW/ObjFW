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

#import <wchar.h>
#import "OFConstWideCString.h"

@implementation OFConstWideCString
- initAsConstWideCString: (const wchar_t*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = wcslen(str);
			string = str;
		}
	}
	return self;
}

- (const wchar_t*)wCString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (OFString*)clone
{
	return [OFString newAsConstWideCString: string];
}

- (int)compareTo: (OFString*)str
{
	return wcscmp(string, [str wCString]);
}
@end
