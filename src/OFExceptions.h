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

#import <stddef.h>
#import "OFObject.h"

// FIXME: Exceptions should include which type of error occoured (fopen etc.)

@interface OFException: OFObject
{
	id   object;
	char *string;
}

+ newWithObject: (id)obj;
- initWithObject: (id)obj;
- free;
- raise;
- (char*)cString;
@end

@interface OFNoMemException: OFException
{
	size_t req_size;
}

+ newWithObject: (id)obj
	andSize: (size_t)size;
- initWithObject: (id)obj
	 andSize: (size_t)size;
- (char*)cString;
- (size_t)requestedSize;
@end

@interface OFNotImplementedException: OFException
{
	SEL selector;
}

+ newWithObject: (id)obj
    andSelector: (SEL)sel;
- initWithObject: (id)obj
     andSelector: (SEL)sel;
- (char*)cString;
- (SEL)selector;
@end

@interface OFMemNotPartOfObjException: OFException
{
	void *pointer;
}

+ newWithObject: (id)obj
     andPointer: (void*)ptr;
- initWithObject: (id)obj
      andPointer: (void*)ptr;
- (char*)cString;
- (void*)pointer;
@end

@interface OFOutOfRangeException: OFException
+ newWithObject: (id)obj;
- initWithObject: (id)obj;
@end

@interface OFOpenFileFailedException: OFException
{
	char *path;
	char *mode;
}

+ newWithObject: (id)obj
	andPath: (const char*)p
	andMode: (const char*)m;
- initWithObject: (id)obj
	 andPath: (const char*)p
	 andMode: (const char*)m;
- free;
- (char*)cString;
- (char*)path;
- (char*)mode;
@end

@interface OFReadOrWriteFailedException: OFException
{
	size_t req_size;
	size_t req_items;
}

+ newWithObject: (id)obj
	andSize: (size_t)size
      andNItems: (size_t)nitems;
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems;
- (size_t)requestedSize;
- (size_t)requestedItems;
@end

@interface OFReadFailedException: OFReadOrWriteFailedException
- (char*)cString;
@end

@interface OFWriteFailedException: OFReadOrWriteFailedException
- (char*)cString;
@end
