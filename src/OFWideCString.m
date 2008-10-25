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

- (size_t)length
{
	return length;
}

- (OFString*)clone
{
	return [OFString newAsWideCString: string];
}

- (int)compareTo: (OFString*)str
{
	return wcscmp(string, [str wcString]);
}

- (OFString*)append: (OFString*)str
{
	return [self appendWideCString: [str wcString]];
}

- (OFString*)appendWideCString: (const wchar_t*)str
{
	wchar_t	*newstr;
	size_t	newlen, strlength;

	if (string == NULL) 
		return [self setTo: [OFString
					newAsWideCString: (wchar_t*)str]];

	strlength = wcslen(str);
	newlen = length + strlength;

	newstr = [self resizeMem: string
			  toSize: (newlen + 1) * sizeof(wchar_t)];

	wmemcpy(newstr + length, str, strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}
@end
