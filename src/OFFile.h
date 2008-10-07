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

#import <stdio.h>

#import "OFObject.h"

@interface OFFile: OFObject
{
	FILE *fp;
}

+ newWithPath: (const char*)path
      andMode: (const char*)mode;
- initWithPath: (const char*)path
       andMode: (const char*)mode;
- free;
- (char*)readWithSize: (size_t)size
	    andNItems: (size_t)nitems;
@end
