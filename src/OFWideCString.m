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
#import <wchar.h>
#import "OFWideCString.h"
#import "OFExceptions.h"

@implementation OFWideCString
- initWithWideCString: (wchar_t*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = wcslen(str);
			string = [self getMemWithSize: (length + 1) *
							   sizeof(wchar_t)];
			wmemcpy(string, str, length + 1);
		}
	}
	return self;
}

- (wchar_t*)wcString
{
	return string;
}

- (OFString*)clone
{
	return [OFString newWithWideCString: string];
}

- (int)compareTo: (OFString*)str
{
	return wcscmp(string, [str wcString]);
}

- (OFString*)append: (OFString*)str
{
	wchar_t	*newstr;
	size_t	newlen, strlength;

	if ([str wcString] == NULL)
		return [self setTo: str];

	strlength = [str length];
	newlen = length + strlength;

	newstr = [self resizeMem: string
			  toSize: (newlen + 1) * sizeof(wchar_t)];

	wmemcpy(newstr + length, [str wcString], strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}
@end
