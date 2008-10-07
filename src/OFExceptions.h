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

@interface OFException: OFObject
+ newWithObject: (id)obj;
- initWithObject: (id)obj;
@end

@interface OFNoMemException: OFException
+ newWithObject: (id)obj
	andSize: (size_t)size;
- initWithObject: (id)obj
	 andSize: (size_t)size;
@end

@interface OFNotImplementedException: OFException
+ newWithObject: (id)obj
      andMethod: (const char*)method;
- initWithObject: (id)obj
       andMethod: (const char*)method;
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

@interface OFReadFailedException: OFException
+ newWithObject: (id)obj
	andSize: (size_t)size
      andNItems: (size_t)nitems;
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems;
@end
