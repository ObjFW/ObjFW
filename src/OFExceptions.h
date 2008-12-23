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
 * \return An error message for the exception as a C string
 */
- (const char*)cString;
@end

/**
 * An OFException indicating there is not enough memory available.
 */
@interface OFNoMemException: OFException
{
	size_t req_size;
}

/**
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
 * \return An error message for the exception as a C string
 */
- (const char*)cString;

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
 * \return An error message for the exception as a C string
 */
- (const char*)cString;

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
 * \return An error message for the exception as a C string
 */
- (const char*)cString;
@end

/**
 * An OFException indicating that the encoding is invalid for this object.
 */
@interface OFInvalidEncodingException: OFException {}
/**
 * \return An error message for the exception as a C string
 */
- (const char*)cString;
@end

/**
 * An OFException indicating that initializing something failed.
 */
@interface OFInitializationFailedException: OFException
{
	Class class;
}

/**
 * Creates a new exception.
 *
 * \param class The class which caused the exception
 * \return A new exception
 */
+ newWithClass: (Class)class;

/**
 * Initializes an already allocated OFException.
 *
 * \param obj The object which caused the exception
 * \return An initialized OFException
 */
- initWithClass: (Class)class;

/**
 * \return An error message for the exception as a C string
 */
- (const char*)cString;

/**
 * \return The class which caused the exception
 */
- (Class)class;
@end

/**
 * An OFException indicating the file couldn't be opened.
 */
@interface OFOpenFileFailedException: OFException
{
	char *path;
	char *mode;
	int  err;
}

/**
 * \param obj The object which caused the exception
 * \param path A C string of the path to the file tried to open
 * \param mode A C string of the mode in which the file should have been opened
 * \return A new open file failed exception
 */
+ newWithObject: (id)obj
	andPath: (const char*)path
	andMode: (const char*)mode;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param obj The object which caused the exception
 * \param path A C string of the path to the file which couldn't be opened
 * \param mode A C string of the mode in which the file should have been opened
 * \return An initialized open file failed exception
 */
- initWithObject: (id)obj
	 andPath: (const char*)path
	 andMode: (const char*)mode;

- free;

/**
 * \return An error message for the exception as a C string
 */
- (const char*)cString;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

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
	BOOL   has_items;
	int    err;
}

/**
 * \param obj The object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \param nitems The requested number of items that couldn't be read / written
 * \return A new open file failed exception
 */
+ newWithObject: (id)obj
	andSize: (size_t)size
      andNItems: (size_t)nitems;

/**
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
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The requested size of the data that couldn't be read / written
 */
- (size_t)requestedSize;

/**
 * \return The requested number of items that coudln't be read / written
 */
- (size_t)requestedItems;

/**
 * \return Whether NItems was specified
 */
- (BOOL)hasNItems;
@end

/**
 * An OFException indicating a read to the file failed.
 */
@interface OFReadFailedException: OFReadOrWriteFailedException {}
/**
 * \return An error message for the exception as a C string
 */
- (const char*)cString;
@end

/**
 * An OFException indicating a write to the file failed.
 */
@interface OFWriteFailedException: OFReadOrWriteFailedException {}
/**
 * \return An error message for the exception as a C string
 */
- (const char*)cString;
@end

/**
 * An OFException indicating that setting an option failed.
 */
@interface OFSetOptionFailedException: OFException {}
/***
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;
@end

/**
 * An OFException indicating a socket is not connected or bound.
 */
@interface OFNotConnectedException: OFException {}
/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;
@end

/**
 * An OFException indicating an attempt to connect or bind an already connected
 * or bound socket.
 */
@interface OFAlreadyConnectedException: OFException {}
/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;
@end

/**
 * An OFException indicating that the specified port is invalid.
 */
@interface OFInvalidPortException: OFException {}
/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;
@end

/**
 * An OFException indicating the translation of an address failed.
 */
@interface OFAddressTranslationFailedException: OFException
{
	char *node;
	char *service;
	int  err;
}

/**
 * \param obj The object which caused the exception
 * \param node The node for which translation was requested
 * \param service The service of the node for which translation was requested
 * \return A new address translation failed exception
 */
+ newWithObject: (id)obj
	andNode: (const char*)node
     andService: (const char*)service;

/**
 * Initializes an already allocated address translation failed exception.
 *
 * \param obj The object which caused the exception
 * \param node The node for which translation was requested
 * \param service The service of the node for which translation was requested
 * \return An initialized address translation failed exception
 */
- initWithObject: (id)obj
	 andNode: (const char*)node
      andService: (const char*)service;

- free;

/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * /return The node for which translation was requested
 */
- (const char*)node;

/**
 * \return The service of the node for which translation was requested
 */
- (const char*)service;
@end

/**
 * An OFException indicating that the connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	char	 *host;
	uint16_t port;
	int	 err;
}

/**
 * \param obj The object which caused the exception
 * \param host The host to which the connection failed
 * \param port The port on the host to which the connection failed
 * \return A new connection failed exception
 */
+ newWithObject: (id)obj
	andHost: (const char*)host
	andPort: (uint16_t)port;

/**
 * Initializes an already allocated connection failed exception.
 *
 * \param obj The object which caused the exception
 * \param host The host to which the connection failed
 * \param port The port on the host to which the connection failed
 * \return An initialized connection failed exception
 */
- initWithObject: (id)obj
	 andHost: (const char*)host
	 andPort: (uint16_t)port;

- free;

/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The host to which the connection failed
 */
- (const char*)host;

/**
 * \return The port on the host to which the connection failed
 */
- (uint16_t)port;
@end

/**
 * An OFException indicating that binding the socket failed.
 */
@interface OFBindFailedException: OFException
{
	char	 *host;
	uint16_t port;
	int	 family;
	int	 err;
}

/**
 * \param obj The object which caused the exception
 * \param host The host on which binding failed
 * \param port The port on which binding failed
 * \param family The family for which binnding failed
 * \return A new bind failed exception
 */
+ newWithObject: (id)obj
	andHost: (const char*)host
	andPort: (uint16_t)port
      andFamily: (int)family;

/**
 * Initializes an already allocated bind failed exception.
 *
 * \param obj The object which caused the exception
 * \param host The host on which binding failed
 * \param port The port on which binding failed
 * \param family The family for which binnding failed
 * \return An initialized bind failed exception
 */
- initWithObject: (id)obj
	 andHost: (const char*)host
	 andPort: (uint16_t)port
       andFamily: (int)family;

- free;

/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The host on which binding failed
 */
- (const char*)host;

/**
 * \return The port on which binding failed
 */
- (uint16_t)port;

/**
 * \return The family for which binding failed
 */
- (int)family;
@end

/**
 * An OFException indicating that listening on the socket failed.
 */
@interface OFListenFailedException: OFException
{
	int backlog;
	int err;
}

/**
 * \param obj The object which caused the exception
 * \param backlog The requested size of the back log
 * \return A new listen failed exception
 */
+ newWithObject: (id)obj
     andBackLog: (int)backlog;

/**
 * Initializes an already allocated listen failed exception
 *
 * \param obj The object which caused the exception
 * \param backlog The requested size of the back log
 * \return An initialized listen failed exception
 */
- initWithObject: (id)obj
      andBackLog: (int)backlog;

/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The requested back log.
 */
- (int)backLog;
@end

/**
 * An OFException indicating that accepting a connection failed.
 */
@interface OFAcceptFailedException: OFException
{
	int err;
}

/**
 * Initializes an already allocated accept failed exception.
 *
 * \param obj The object which caused the exception
 * \return An initialized accept failed exception
 */
- initWithObject: (id)obj;

/**
 * \return An error message for the exception as a C string.
 */
- (const char*)cString;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end
