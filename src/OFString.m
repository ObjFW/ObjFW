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
#import <ctype.h>

#import "OFString.h"
#import "OFExceptions.h"

@implementation OFString
+ new
{
	return [[self alloc] init];
}

+ newFromCString: (const char*)str
{
	return [[self alloc] initFromCString: str];
}

- init
{
	if ((self = [super init])) {
		length = 0;
		string = NULL;
	}

	return self;
}

- initFromCString: (const char*)str
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

- (const char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (OFString*)clone
{
	return [OFString newFromCString: string];
}

- (OFString*)setTo: (OFString*)str
{
	[self free];
	return (self = [str clone]);
}

- (int)compareTo: (OFString*)str
{
	return strcmp(string, [str cString]);
}

- append: (OFString*)str
{
	return [self appendCString: [str cString]];
}

- appendCString: (const char*)str
{
	char   *newstr;
	size_t newlen, strlength;

	if (string == NULL) 
		return [self setTo: [OFString newFromCString: str]];

	strlength = strlen(str);
	newlen = length + strlength;

	newstr = [self resizeMem: string
			  toSize: newlen + 1];

	memcpy(newstr + length, str, strlength + 1);

	length = newlen;
	string = newstr;

	return self;
}

- reverse
{
	size_t i, j, len = length / 2;

	for (i = 0, j = length - 1; i < len; i++, j--) {
		string[i] ^= string[j];
		string[j] ^= string[i];
		string[i] ^= string[j];
	}

	return self;
}

- upper
{
	size_t i = length;

	while (i--) 
		string[i] = toupper(string[i]);

	return self;
}

- lower
{
	size_t i = length;

	while (i--) 
		string[i] = tolower(string[i]);

	return self;
}
@end
