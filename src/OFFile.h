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
#import <stdint.h>

#import "OFObject.h"

@interface OFFile: OFObject
{
	FILE *fp;
}

+ newWithPath: (const char*)path
      andMode: (const char*)mode;
+ (int)changeModeOfFile: (const char*)path
		 toMode: (mode_t)mode;
+ (int)changeOwnerOfFile: (const char*)path
		 toOwner: (uid_t)owner
		andGroup: (gid_t)group;
+ (int)delete: (const char*)path;
+ (int)link: (const char*)src
	 to: (const char*)dest;
+ (int)symlink: (const char*)src
	    to: (const char*)dest;

- initWithPath: (const char*)path
       andMode: (const char*)mode;
- free;
- (BOOL)atEndOfFile;
- (size_t)readIntoBuffer: (uint8_t*)buf
		withSize: (size_t)size
	       andNItems: (size_t)nItems;
- (uint8_t*)readWithSize: (size_t)size
	       andNItems: (size_t)nitems;
- (size_t)writeBuffer: (uint8_t*)buf
	     withSize: (size_t)size
	    andNItems: (size_t)nitems;
@end
