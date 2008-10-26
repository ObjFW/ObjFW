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
	char *errstr;
}

+ newWithObject: (id)obj;
- initWithObject: (id)obj;
- free;
- raise;
- (char*)string;
@end

@interface OFNoMemException: OFException
+ newWithObject: (id)obj
	andSize: (size_t)size;
- initWithObject: (id)obj
	 andSize: (size_t)size;
@end

@interface OFNotImplementedException: OFException
+ newWithObject: (id)obj
    andSelector: (SEL)sel;
- initWithObject: (id)obj
     andSelector: (SEL)sel;
@end

@interface OFMemNotPartOfObjException: OFException
+ newWithObject: (id)obj
     andPointer: (void*)ptr;
- initWithObject: (id)obj
      andPointer: (void*)ptr;
@end

@interface OFOverflowException: OFException
+ newWithObject: (id)obj;
- initWithObject: (id)obj;
@end

@interface OFOpenFileFailedException: OFException
+ newWithObject: (id)obj
	andPath: (const char*)path
	andMode: (const char*)mode;
- initWithObject: (id)obj
	 andPath: (const char*)path
	 andMode: (const char*)mode;
@end

@interface OFReadOrWriteFailedException: OFException
+ newWithObject: (id)obj
	andSize: (size_t)size
      andNItems: (size_t)nitems;
@end

@interface OFReadFailedException: OFReadOrWriteFailedException
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems;
@end

@interface OFWriteFailedException: OFReadOrWriteFailedException
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems;
@end
