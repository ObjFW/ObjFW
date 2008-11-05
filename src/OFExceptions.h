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

/* FIXME: Exceptions should include which type of error occoured (fopen etc.) */

/**
 * The OFException class is the base class for all exceptions in ObjFW.
 */
@interface OFException: OFObject
{
	id   object;
	char *string;
}

/**
 * Creates a new exception.
 *
 * \param obj The object which caused the exception
 * \return A new exception
 */
+ newWithObject: (id)obj;

/**
 * Initializes an already allocated OFException.
 *
 * \param obj The object which caused the exception
 * \return An initialized OFException
 */
- initWithObject: (id)obj;

/**
 * Frees an OFException and the memory it allocated.
 */
- free;

/**
 * Raises an OFException and aborts execution if the exception is not caught.
 */

- raise;

/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;
@end

/**
 * An OFException indicating there is not enough memory available.
 */
@interface OFNoMemException: OFException
{
	size_t req_size;
}

/**
 * Creates a new no memory exception.
 *
 * \param obj The object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return A new no memory exception
 */
+ newWithObject: (id)obj
	andSize: (size_t)size;

/**
 * Initializes an already allocated no memory exception.
 *
 * \param obj The object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return An initialized new no memory exception
 */
- initWithObject: (id)obj
	 andSize: (size_t)size;

/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;

/**
 * \return The size of the memoory that couldn't be allocated
 */
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
