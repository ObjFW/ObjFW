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
#import "OFConstString.h"

@implementation OFConstString
+ new:(const char*)str
{
	return [[OFConstString alloc] init:str];
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
			string = str;
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
@end
