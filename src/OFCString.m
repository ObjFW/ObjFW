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

#import "OFCString.h"
#import "OFExceptions.h"

@implementation OFCString
- initWithCString: (const char*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = strlen(str);
			string = [self getMemWithSize: length + 1];
			memcpy(string, str, length + 1);
		}
	}
	return self;
}

- (char*)cString
{
	return string;
}

- (OFString*)clone
{
	return [OFString newWithCString: string];
}

- (int)compareTo: (OFString*)str
{
	return strcmp(string, [str cString]);
}

- (OFString*)append: (OFString*)str
{
	char   *newstr;
	size_t newlen, strlength;

	if (str == NULL)
		return [self setTo: str];

	strlength = [str length];
	newlen = length + strlength;

	newstr = [self resizeMem: string
			  toSize: newlen + 1];

	memcpy(newstr + length, [str cString], strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}
@end
