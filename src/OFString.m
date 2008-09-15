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
#import "OFString.h"
#import "OFExceptions.h"

@implementation OFString
+ new: (const char*)str
{
	return [[OFString alloc] init: str];
}

- init
{
	return [self init: NULL];
}

- init: (const char*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = strlen(str);
			string = [self getMem: length + 1];
			memcpy(string, str, length + 1);
		}
	}
	return self;
}

- (char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (OFString*)setTo: (OFConstString*)str
{
	char *newstr;
	size_t newlen;
	
	if ([str cString] == NULL) {
		[self freeMem: string];

		length = 0;
		string = NULL;

		return self;
	}

	newlen = [str length];
	newstr = [self getMem: newlen + 1];
	memcpy(newstr, [str cString], newlen + 1);

	if (string != NULL)
		[self freeMem: string];

	length = newlen;
	string = newstr;

	return self;
}

- (OFString*)clone
{
	return [OFString new: string];
}

- (OFString*)append: (OFConstString*)str
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

- (int)compare: (OFConstString*)str
{
	return strcmp(string, [str cString]);
}
@end
