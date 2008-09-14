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
#import "OFConstWideString.h"

@implementation OFConstWideString
+ new:(const wchar_t*)wstr
{
	return [[OFConstWideString alloc] init:wstr];
}

- init
{
	return [self init:NULL];
}

- init:(const wchar_t*)wstr
{
	if ((self = [super init])) {
		if (wstr == NULL) {
			length = 0;
			wstring = NULL;
		} else {
			length = wcslen(wstr);
			wstring = wstr;
		}
	}
	return self;
}

- (const wchar_t*)wcString
{
	return wstring;
}

- (size_t)length
{
	return length;
}
@end
