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
#import "OFConstWideCString.h"

@implementation OFConstWideCString
- initWithConstWideCString: (const wchar_t*)str
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

- (const wchar_t*)wcString
{
	return string;
}

- (OFString*)clone
{
	return [OFString newWithConstWideCString: string];
}

- (int)compare: (OFString*)str
{
	return wcscmp(string, [str wcString]);
}
@end
