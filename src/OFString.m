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
			string = NULL;
			length = 0;
		} else {
			string = strdup(str);
			length = strlen(string);
		}
	}
	return self;
}

- free
{
	if (string != NULL)
		free(string);
	return [super free];
}

- (char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (void)setTo:(const char*)str
{
	if (string != NULL)
		free(string);

	string = strdup(str);
	length = strlen(str);
}

- (OFString*)clone
{
	if (string != NULL)
		return [OFString new:string];
	return [OFString new];
}

- (void)append: (const char*)str
{
	char	*new_string;
	size_t	new_length, str_length;

	if (str == NULL) {
		[self setTo:str];
		return;
	}

	str_length = strlen(str);
	new_length = length + str_length;

	if ((new_string = realloc(string, new_length + 1)) == NULL) {
		/* FIXME: Add error handling */
		return;
	}

	string = new_string;

	memcpy(string + length, str, str_length);
	string[new_length] = '\0';

	length = new_length;
}
@end
