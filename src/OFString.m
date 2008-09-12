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

/* TODO: Use getMem / resizeMem */

@implementation OFString
+ new:(const char*)str
{
	return [[OFString alloc] init:str];
}

- init
{
	return [self init:NULL];
}

- init:(const char*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = strlen(string);
			if ((string = [self getMem:length]) == NULL)
				return NULL;
			memcpy(string, str, length);
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

- (OFString*)setTo:(const char*)str
{
	char *newstr;
	size_t newlen;
	
	if (str == NULL) {
		[self freeMem:string];

		length = 0;
		string = NULL;

		return self;
	}

	newlen = strlen(str);
	if ((newstr = [self getMem:newlen]) == NULL)
		return nil;
	memcpy(newstr, str, newlen);

	if (string != NULL)
		[self freeMem:string];

	length = newlen;
	string = newstr;

	return self;
}

- (OFString*)clone
{
	if (string != NULL)
		return [OFString new:string];
	return [OFString new];
}

- (OFString*)append: (const char*)str
{
	char	*new_string;
	size_t	new_length, str_length;

	if (str == NULL)
		return [self setTo:str];

	str_length = strlen(str);
	new_length = length + str_length;

	if ((new_string =
	    [self resizeMem:string toSize:new_length + 1]) == NULL) {
		/* FIXME: Add error handling */
		return nil;
	}

	string = new_string;

	memcpy(string + length, str, str_length);
	string[new_length] = '\0';

	length = new_length;

	return self;
}
@end
