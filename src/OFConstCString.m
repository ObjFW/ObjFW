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

#import <string.h>
#import "OFConstCString.h"

@implementation OFConstCString
- initWithConstCString: (const char*)str
{
	if ((self = [super init])) {
		if (str == NULL) {
			length = 0;
			string = NULL;
		} else {
			length = strlen(str);
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

- (OFString*)clone
{
	return [OFString newWithConstCString: string];
}

- (int)compareTo: (OFString*)str
{
	return strcmp(string, [str cString]);
}
@end
