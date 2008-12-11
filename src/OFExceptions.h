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

#import "OFObject.h"

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

- free;

/**
 * \return The object that caused the exception
 */
- (id)object;

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
 * \return An initialized no memory exception
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

/**
 * An OFException indicating the given memory is not part of the object.
 */
@interface OFMemNotPartOfObjException: OFException
{
	void *pointer;
}

/**
 * Creates a new memory not part of object exception.
 *
 * \param obj The object which caused the exception
 * \param ptr A pointer to the memory that is not part of the object
 * \return A new memory not part of object exception
 */
+ newWithObject: (id)obj
     andPointer: (void*)ptr;

/**
 * Initializes an already allocated memory not part of object exception.
 *
 * \param obj The object which caused the exception
 * \param ptr A pointer to the memory that is not part of the object
 * \return An initialized memory not part of object exception
 */
- initWithObject: (id)obj
      andPointer: (void*)ptr;

/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;

/**
 * \return A pointer to the memory which is not part of the object
 */
- (void*)pointer;
@end

/**
 * An OFException indicating the given value is out of range. 
 */
@interface OFOutOfRangeException: OFException {}
/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;
@end

/**
 * An OFException indicating that the conversation between two charsets failed.
 */
@interface OFCharsetConversionFailedException: OFException {}
/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;
@end

/**
 * An OFException indicating the file couldn't be opened.
 */
@interface OFOpenFileFailedException: OFException
{
	char *path;
	char *mode;
}

/**
 * Creates a new open file failed exception.
 *
 * \param obj The object which caused the exception
 * \param p A C string of the path to the file tried to open
 * \param m A C string of the mode in which the file should have been opened
 * \return A new open file failed exception
 */
+ newWithObject: (id)obj
	andPath: (const char*)p
	andMode: (const char*)m;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param obj The object which caused the exception
 * \param p A C string of the path to the file which couldn't be opened
 * \param m A C string of the mode in which the file should have been opened
 * \return An initialized open file failed exception
 */
- initWithObject: (id)obj
	 andPath: (const char*)p
	 andMode: (const char*)m;

- free;

/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;

/**
 * \return A C string of the path to the file which couldn't be opened
 */
- (char*)path;

/**
 * \return A C string of the mode in which the file should have been opened
 */
- (char*)mode;
@end

/**
 * An OFException indicating a read or write to the file failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	size_t req_size;
	size_t req_items;
	BOOL has_items;
}

/**
 * Creates a new read or write failed exception.
 *
 * \param obj The object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \param nitems The requested number of items that couldn't be read / written
 * \return A new open file failed exception
 */
+ newWithObject: (id)obj
	andSize: (size_t)size
      andNItems: (size_t)nitems;

/**
 * Creates a new read or write failed exception.
 *
 * \param obj The object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
+ newWithObject: (id)obj
	andSize: (size_t)size;

/**
 * Initializes an already allocated read or write failed exception.
 *
 * \param obj The object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \param nitems The requested number of items that couldn't be read / written
 * \return A new open file failed exception
 */
- initWithObject: (id)obj
	 andSize: (size_t)size
       andNItems: (size_t)nitems;

/**
 * Initializes an already allocated read or write failed exception.
 *
 * \param obj The object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
- initWithObject: (id)obj
	 andSize: (size_t)size;

/**
 * \return The requested size of the data that couldn't be read / written
 */
- (size_t)requestedSize;

/**
 * \return The requested number of items that coudln't be read / written
 */
- (size_t)requestedItems;
@end

/**
 * An OFException indicating a read to the file failed.
 */
@interface OFReadFailedException: OFReadOrWriteFailedException {}
/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;
@end

/**
 * An OFException indicating a write to the file failed.
 */
@interface OFWriteFailedException: OFReadOrWriteFailedException {}
/**
 * \return An error message for the exception as a C String
 */
- (char*)cString;
@end

/**
 * An OFException indicating a socket is not connected or bound.
 */
@interface OFNotConnectedException: OFException {}
/**
 * \return An error message for the exception as a C string.
 */
- (char*)cString;
@end

/**
 * An OFException indicating an attempt to connect or bind an already connected
 * or bound socket 
 */
@interface OFAlreadyConnectedException: OFException {}
/**
 * \return An error message for the exception as a C string.
 */
- (char*)cString;
@end

/**
 * An OFException indicating that the specified port is invalid.
 */
@interface OFInvalidPortException: OFException
/**
 * \return An error message for the exception as a C string.
 */
- (char*)cString;
@end
