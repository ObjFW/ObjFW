/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFString.h"

/**
 * An exception indicating an object could not be allocated.
 *
 * This exception is preallocated, as if there's no memory, no exception can
 * be allocated of course. That's why you shouldn't and even can't deallocate
 * it.
 *
 * This is the only exception that is not an OFException as it's special.
 * It does not know for which class allocation failed and it should not be
 * handled like other exceptions, as the exception handling code is not
 * allowed to allocate ANY memory.
 */
@interface OFAllocFailedException
{
	Class isa;
}

+ (Class)class;

/**
 * \return An error message for the exception as a string
 */
- (OFString*)string;
@end

/**
 * The OFException class is the base class for all exceptions in ObjFW.
 *
 * IMPORTANT: Exceptions do NOT use OFAutoreleasePools!!
 */
@interface OFException: OFObject
{
	Class	 class_;
	OFString *string;
}

/**
 * Creates a new exception.
 *
 * \param class_ The class of the object which caused the exception
 * \return A new exception
 */
+ newWithClass: (Class)class_;

/**
 * Initializes an already allocated OFException.
 *
 * \param class_ The class of the object which caused the exception
 * \return An initialized OFException
 */
- initWithClass: (Class)class_;

/**
 * \return The class of the object in which the exception happened
 */
- (Class)inClass;

/**
 * \return An error message for the exception as a string
 */
- (OFString*)string;
@end

/**
 * An OFException indicating there is not enough memory available.
 */
@interface OFOutOfMemoryException: OFException
{
	size_t req_size;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return A new no memory exception
 */
+ newWithClass: (Class)class_
	  size: (size_t)size;

/**
 * Initializes an already allocated no memory exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return An initialized no memory exception
 */
- initWithClass: (Class)class_
	   size: (size_t)size;

/**
 * \return The size of the memoory that couldn't be allocated
 */
- (size_t)requestedSize;
@end

/**
 * An OFException indicating the given memory is not part of the object.
 */
@interface OFMemoryNotPartOfObjectException: OFException
{
	void *pointer;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param ptr A pointer to the memory that is not part of the object
 * \return A new memory not part of object exception
 */
+ newWithClass: (Class)class_
       pointer: (void*)ptr;

/**
 * Initializes an already allocated memory not part of object exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param ptr A pointer to the memory that is not part of the object
 * \return An initialized memory not part of object exception
 */
- initWithClass: (Class)class_
	pointer: (void*)ptr;

/**
 * \return A pointer to the memory which is not part of the object
 */
- (void*)pointer;
@end

/**
 * An OFException indicating that a method or part of it is not implemented.
 */
@interface OFNotImplementedException: OFException
{
	SEL selector;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param selector The selector which is not or not fully implemented
 * \return A new not implemented exception
 */
+ newWithClass: (Class)class_
      selector: (SEL)selector;

/**
 * Initializes an already allocated not implemented exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param selector The selector which is not or not fully implemented
 * \return An initialized not implemented exception
 */
- initWithClass: (Class)class_
       selector: (SEL)selector;
@end

/**
 * An OFException indicating the given value is out of range.
 */
@interface OFOutOfRangeException: OFException {}
@end

/**
 * An OFException indicating that the argument is invalid for this method.
 */
@interface OFInvalidArgumentException: OFException
{
	SEL selector;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param selector The selector which doesn't accept the argument
 * \return A new invalid argument exception
 */
+ newWithClass: (Class)class_
      selector: (SEL)selector;

/**
 * Initializes an already allocated invalid argument exception
 *
 * \param class_ The class of the object which caused the exception
 * \param selector The selector which doesn't accept the argument
 * \return An initialized invalid argument exception
 */
- initWithClass: (Class)class_
       selector: (SEL)selector;
@end

/**
 * An OFException indicating that the encoding is invalid for this object.
 */
@interface OFInvalidEncodingException: OFException {}
@end

/**
 * An OFException indicating that the format is invalid.
 */
@interface OFInvalidFormatException: OFException {}
@end

/**
 * An OFException indicating that a parser encountered malformed or invalid XML.
 */
@interface OFMalformedXMLException: OFException {}
@end

/**
 * An OFException indicating that initializing something failed.
 */
@interface OFInitializationFailedException: OFException {}
@end

/**
 * An OFException indicating the file couldn't be opened.
 */
@interface OFOpenFileFailedException: OFException
{
	OFString *path;
	OFString *mode;
	int  err;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param path A string of the path to the file tried to open
 * \param mode A string of the mode in which the file should have been opened
 * \return A new open file failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path
	  mode: (OFString*)mode;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path A string of the path to the file which couldn't be opened
 * \param mode A string of the mode in which the file should have been opened
 * \return An initialized open file failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	   mode: (OFString*)mode;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string of the path to the file which couldn't be opened
 */
- (OFString*)path;

/**
 * \return A string of the mode in which the file should have been opened
 */
- (OFString*)mode;
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
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \param items The requested number of items that couldn't be read / written
 * \return A new open file failed exception
 */
+ newWithClass: (Class)class_
	  size: (size_t)size
	 items: (size_t)items;

/**
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
+ newWithClass: (Class)class_
	  size: (size_t)size;

/**
 * Initializes an already allocated read or write failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \param items The requested number of items that couldn't be read / written
 * \return A new open file failed exception
 */
- initWithClass: (Class)class_
	   size: (size_t)size
	  items: (size_t)items;

/**
 * Initializes an already allocated read or write failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
- initWithClass: (Class)class_
	   size: (size_t)size;

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
@end

/**
 * An OFException indicating a write to the file failed.
 */
@interface OFWriteFailedException: OFReadOrWriteFailedException {}
@end

/**
 * An OFException indicating that creating a link failed.
 */
@interface OFLinkFailedException: OFException
{
	OFString *src;
	OFString *dest;
	int err;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param source The source for the link
 * \param destination The destination for the link
 * \return A new link failed exception
 */
+ newWithClass: (Class)class_
	source: (OFString*)src
   destination: (OFString*)dest;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param source The source for the link
 * \param destination The destination for the link
 * \return An initialized link failed exception
 */
- initWithClass: (Class)class_
	 source: (OFString*)src
    destination: (OFString*)dest;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string of the source for the link
 */
- (OFString*)source;

/**
 * \return A string of the destination for the link
 */
- (OFString*)destination;
@end

/**
 * An OFException indicating that creating a symlink failed.
 */
@interface OFSymlinkFailedException: OFException
{
	OFString *src;
	OFString *dest;
	int err;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param source The source for the symlink
 * \param destination The destination for the symlink
 * \return A new symlink failed exception
 */
+ newWithClass: (Class)class_
	source: (OFString*)src
   destination: (OFString*)dest;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param source The source for the symlink
 * \param destination The destination for the symlink
 * \return An initialized symlink failed exception
 */
- initWithClass: (Class)class_
	 source: (OFString*)src
    destination: (OFString*)dest;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string of the source for the symlink
 */
- (OFString*)source;

/**
 * \return A string of the destination for the symlink
 */
- (OFString*)destination;
@end

/**
 * An OFException indicating that setting an option failed.
 */
@interface OFSetOptionFailedException: OFException {}
@end

/**
 * An OFException indicating a socket is not connected or bound.
 */
@interface OFNotConnectedException: OFException {}
@end

/**
 * An OFException indicating an attempt to connect or bind an already connected
 * or bound socket.
 */
@interface OFAlreadyConnectedException: OFException {}
@end

/**
 * An OFException indicating the translation of an address failed.
 */
@interface OFAddressTranslationFailedException: OFException
{
	OFString *node;
	OFString *service;
	int	 err;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param node The node for which translation was requested
 * \param service The service of the node for which translation was requested
 * \return A new address translation failed exception
 */
+ newWithClass: (Class)class_
	  node: (OFString*)node
       service: (OFString*)service;

/**
 * Initializes an already allocated address translation failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param node The node for which translation was requested
 * \param service The service of the node for which translation was requested
 * \return An initialized address translation failed exception
 */
- initWithClass: (Class)class_
	   node: (OFString*)node
	service: (OFString*)service;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * /return The node for which translation was requested
 */
- (OFString*)node;

/**
 * \return The service of the node for which translation was requested
 */
- (OFString*)service;
@end

/**
 * An OFException indicating that the connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	OFString *node;
	OFString *service;
	int	 err;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param node The node to which the connection failed
 * \param service The service on the node to which the connection failed
 * \return A new connection failed exception
 */
+ newWithClass: (Class)class_
	  node: (OFString*)node
       service: (OFString*)service;

/**
 * Initializes an already allocated connection failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param node The node to which the connection failed
 * \param service The service on the node to which the connection failed
 * \return An initialized connection failed exception
 */
- initWithClass: (Class)class_
	   node: (OFString*)node
	service: (OFString*)service;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The node to which the connection failed
 */
- (OFString*)node;

/**
 * \return The service on the node to which the connection failed
 */
- (OFString*)service;
@end

/**
 * An OFException indicating that binding the socket failed.
 */
@interface OFBindFailedException: OFException
{
	OFString *node;
	OFString *service;
	int	 family;
	int	 err;
}

/**
 * \param class_ The class of the object which caused the exception
 * \param node The node on which binding failed
 * \param service The service on which binding failed
 * \param family The family for which binnding failed
 * \return A new bind failed exception
 */
+ newWithClass: (Class)class_
	  node: (OFString*)node
       service: (OFString*)service
	family: (int)family;

/**
 * Initializes an already allocated bind failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param node The node on which binding failed
 * \param service The service on which binding failed
 * \param family The family for which binnding failed
 * \return An initialized bind failed exception
 */
- initWithClass: (Class)class_
	   node: (OFString*)node
	service: (OFString*)service
	 family: (int)family;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The node on which binding failed
 */
- (OFString*)node;

/**
 * \return The service on which binding failed
 */
- (OFString*)service;

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
 * \param class_ The class of the object which caused the exception
 * \param backlog The requested size of the back log
 * \return A new listen failed exception
 */
+ newWithClass: (Class)class_
       backLog: (int)backlog;

/**
 * Initializes an already allocated listen failed exception
 *
 * \param class_ The class of the object which caused the exception
 * \param backlog The requested size of the back log
 * \return An initialized listen failed exception
 */
- initWithClass: (Class)class_
	backLog: (int)backlog;

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
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end

/**
 * An OFException indicating that joining the thread failed.
 */
@interface OFThreadJoinFailedException: OFException {}
@end

/**
 * An OFException indicating that the thread has been canceled.
 */
@interface OFThreadCanceledException: OFException {}
@end
