/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <sys/types.h>

#import "OFObject.h"

@class OFString;

/**
 * \brief An exception indicating an object could not be allocated.
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
@interface OFAllocFailedException: OFObject
/**
 * \return A description of the exception
 */
- (OFString*)description;
@end

/**
 * \brief The base class for all exceptions in ObjFW
 *
 * The OFException class is the base class for all exceptions in ObjFW, except
 * the OFAllocFailedException.
 *
 * IMPORTANT: Exceptions do NOT use OFAutoreleasePools and can't be autoreleased
 * either! You have to make sure to dealloc the exception in your \@catch block!
 */
@interface OFException: OFObject
{
	Class inClass;
	OFString *description;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) Class inClass;
#endif

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
 * \return A description of the exception
 */
- (OFString*)description;
@end

/**
 * \brief An exception indicating there is not enough memory available.
 */
@interface OFOutOfMemoryException: OFException
{
	size_t requestedSize;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t requestedSize;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return A new no memory exception
 */
+  newWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * Initializes an already allocated no memory exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The size of the memory that couldn't be allocated
 * \return An initialized no memory exception
 */
- initWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * \return The size of the memoory that couldn't be allocated
 */
- (size_t)requestedSize;
@end

/**
 * \brief An exception indicating that a mutation was detected during
 *        enumeration.
 */
@interface OFEnumerationMutationException: OFException {}
@end

/**
 * \brief An exception indicating the given memory is not part of the object.
 */
@interface OFMemoryNotPartOfObjectException: OFException
{
	void *pointer;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) void *pointer;
#endif

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
 * \brief An exception indicating that a method or part of it is not
 *        implemented.
 */
@interface OFNotImplementedException: OFException
{
	SEL selector;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) SEL selector;
#endif

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

/**
 * \return The selector which is not or not fully implemented
 */
- (SEL)selector;
@end

/**
 * \brief An exception indicating the given value is out of range.
 */
@interface OFOutOfRangeException: OFException {}
@end

/**
 * \brief An exception indicating that the argument is invalid for this method.
 */
@interface OFInvalidArgumentException: OFException
{
	SEL selector;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) SEL selector;
#endif

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

/**
 * \return The selector to which an invalid argument was passed
 */
- (SEL)selector;
@end

/**
 * \brief An exception indicating that the encoding is invalid for this object.
 */
@interface OFInvalidEncodingException: OFException {}
@end

/**
 * \brief An exception indicating that the format is invalid.
 */
@interface OFInvalidFormatException: OFException {}
@end

/**
 * \brief An exception indicating that a parser encountered malformed or
 *        invalid XML.
 */
@interface OFMalformedXMLException: OFException {}
@end

/**
 * \brief An exception indicating that initializing something failed.
 */
@interface OFInitializationFailedException: OFException {}
@end

/**
 * \brief An exception indicating a file couldn't be opened.
 */
@interface OFOpenFileFailedException: OFException
{
	OFString *path;
	OFString *mode;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly, nonatomic) OFString *mode;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the file tried to open
 * \param mode A string with the mode in which the file should have been opened
 * \return A new open file failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path
	  mode: (OFString*)mode;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the file which couldn't be opened
 * \param mode A string with the mode in which the file should have been opened
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
 * \return A string with the path of the file which couldn't be opened
 */
- (OFString*)path;

/**
 * \return A string with the mode in which the file should have been opened
 */
- (OFString*)mode;
@end

/**
 * \brief An exception indicating a read or write to a stream failed.
 */
@interface OFReadOrWriteFailedException: OFException
{
	size_t requestedSize;
	int    errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t requestedSize;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
+  newWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * Initializes an already allocated read or write failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param size The requested size of the data that couldn't be read / written
 * \return A new open file failed exception
 */
- initWithClass: (Class)class_
  requestedSize: (size_t)size;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The requested size of the data that couldn't be read / written
 */
- (size_t)requestedSize;
@end

/**
 * \brief An exception indicating a read on a stream failed.
 */
@interface OFReadFailedException: OFReadOrWriteFailedException {}
@end

/**
 * \brief An exception indicating a write to a stream failed.
 */
@interface OFWriteFailedException: OFReadOrWriteFailedException {}
@end

/**
 * \brief An exception indicating that seeking in a stream failed.
 */
@interface OFSeekFailedException: OFException
{
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) int errNo;
#endif

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end

/**
 * \brief An exception indicating a directory couldn't be created.
 */
@interface OFCreateDirectoryFailedException: OFException
{
	OFString *path;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the directory which couldn't be created
 * \return A new create directory failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path;

/**
 * Initializes an already allocated create directory failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the directory which couldn't be created
 * \return An initialized create directory failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string with the path of the file which couldn't be opened
 */
- (OFString*)path;
@end

/**
 * \brief An exception indicating that changing the mode of a file failed.
 */
@interface OFChangeFileModeFailedException: OFException
{
	OFString *path;
	mode_t mode;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly) mode_t mode;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param mode The new mode for the file
 * \return An initialized change file mode failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path
	  mode: (mode_t)mode;

/**
 * Initializes an already allocated change file mode failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param mode The new mode for the file
 * \return An initialized change file mode failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	   mode: (mode_t)mode;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the file
 */
- (OFString*)path;

/**
 * \return The new mode for the file
 */
- (mode_t)mode;
@end

#ifndef _WIN32
/**
 * \brief An exception indicating that changing the owner of a file failed.
 */
@interface OFChangeFileOwnerFailedException: OFException
{
	OFString *path;
	OFString *owner;
	OFString *group;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly, nonatomic) OFString *owner;
@property (readonly, nonatomic) OFString *group;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param owner The new owner for the file
 * \param group The new group for the file
 * \return An initialized change file owner failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path
	 owner: (OFString*)owner
	 group: (OFString*)group;

/**
 * Initializes an already allocated change file owner failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param owner The new owner for the file
 * \param group The new group for the file
 * \return An initialized change file owner failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	  owner: (OFString*)owner
	  group: (OFString*)group;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the file
 */
- (OFString*)path;

/**
 * \return The new owner for the file
 */
- (OFString*)owner;

/**
 * \return The new group for the file
 */
- (OFString*)group;
@end
#endif

/**
 * \brief An exception indicating that copying a file failed.
 */
@interface OFCopyFileFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *sourcePath;
@property (readonly, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param src The original path
 * \param dst The new path
 * \return A new copy file failed exception
 */
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst;

/**
 * Initializes an already allocated copy file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param src The original path
 * \param dst The new path
 * \return An initialized copy file failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the source file
 */
- (OFString*)sourcePath;

/**
 * \return The destination path
 */
- (OFString*)destinationPath;
@end

/**
 * \brief An exception indicating that renaming a file failed.
 */
@interface OFRenameFileFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *sourcePath;
@property (readonly, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param src The original path
 * \param dst The new path
 * \return A new rename file failed exception
 */
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst;

/**
 * Initializes an already allocated rename failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param src The original path
 * \param dst The new path
 * \return An initialized rename file failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The original path
 */
- (OFString*)sourcePath;

/**
 * \return The new path
 */
- (OFString*)destinationPath;
@end

/**
 * \brief An exception indicating that deleting a file failed.
 */
@interface OFDeleteFileFailedException: OFException
{
	OFString *path;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \return A new delete file failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path;

/**
 * Initializes an already allocated delete file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \return An initialized delete file failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the file
 */
- (OFString*)path;
@end

/**
 * \brief An exception indicating that deleting a directory failed.
 */
@interface OFDeleteDirectoryFailedException: OFException
{
	OFString *path;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path The path of the directory
 * \return A new delete directory failed exception
 */
+ newWithClass: (Class)class_
	  path: (OFString*)path;

/**
 * Initializes an already allocated delete directory failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path The path of the directory
 * \return An initialized delete directory failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the directory
 */
- (OFString*)path;
@end

#ifndef _WIN32
/**
 * \brief An exception indicating that creating a link failed.
 */
@interface OFLinkFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *sourcePath;
@property (readonly, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param src The source for the link
 * \param dest The destination for the link
 * \return A new link failed exception
 */
+    newWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest;

/**
 * Initializes an already allocated link failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param src The source for the link
 * \param dest The destination for the link
 * \return An initialized link failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string with the source for the link
 */
- (OFString*)sourcePath;

/**
 * \return A string with the destination for the link
 */
- (OFString*)destinationPath;
@end

/**
 * \brief An exception indicating that creating a symlink failed.
 */
@interface OFSymlinkFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *sourcePath;
@property (readonly, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param src The source for the symlink
 * \param dest The destination for the symlink
 * \return A new symlink failed exception
 */
+   newWithClass: (Class)class_
      sourcePath: (OFString*)src
 destinationPath: (OFString*)dest;

/**
 * Initializes an already allocated symlink failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param src The source for the symlink
 * \param dest The destination for the symlink
 * \return An initialized symlink failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dest;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string with the source for the symlink
 */
- (OFString*)sourcePath;

/**
 * \return A string with the destination for the symlink
 */
- (OFString*)destinationPath;
@end
#endif

/**
 * \brief An exception indicating that setting an option failed.
 */
@interface OFSetOptionFailedException: OFException {}
@end

/**
 * \brief An exception indicating a socket is not connected or bound.
 */
@interface OFNotConnectedException: OFException {}
@end

/**
 * \brief An exception indicating an attempt to connect or bind an already
 *        connected or bound socket.
 */
@interface OFAlreadyConnectedException: OFException {}
@end

/**
 * \brief An exception indicating the translation of an address failed.
 */
@interface OFAddressTranslationFailedException: OFException
{
	OFString *node;
	OFString *service;
	int	 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *node;
@property (readonly, nonatomic) OFString *service;
@property (readonly) int errNo;
#endif

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
 * \brief An exception indicating that a connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	OFString *node;
	OFString *service;
	int	 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *node;
@property (readonly, nonatomic) OFString *service;
@property (readonly) int errNo;
#endif

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
 * \brief An exception indicating that binding a socket failed.
 */
@interface OFBindFailedException: OFException
{
	OFString *node;
	OFString *service;
	int	 family;
	int	 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *node;
@property (readonly, nonatomic) OFString *service;
@property (readonly) int family;
@property (readonly) int errNo;
#endif

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
 * \brief An exception indicating that listening on the socket failed.
 */
@interface OFListenFailedException: OFException
{
	int backLog;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) int backLog;
@property (readonly) int errNo;
#endif

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
 * \brief An exception indicating that accepting a connection failed.
 */
@interface OFAcceptFailedException: OFException
{
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) int errNo;
#endif

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end

/**
 * \brief An exception indicating that starting a thread failed.
 */
@interface OFThreadStartFailedException: OFException {}
@end

/**
 * \brief An exception indicating that joining a thread failed.
 */
@interface OFThreadJoinFailedException: OFException {}
@end

/**
 * \brief An exception indicating that a thread is still running.
 */
@interface OFThreadStillRunningException: OFException {}
@end

/**
 * \brief An exception indicating that locking a mutex failed.
 */
@interface OFMutexLockFailedException: OFException {}
@end

/**
 * \brief An exception indicating that unlocking a mutex failed.
 */
@interface OFMutexUnlockFailedException: OFException {}
@end

/**
 * \brief An exception indicating that the hash has already been calculated.
 */
@interface OFHashAlreadyCalculatedException: OFException {}
@end

/**
 * \brief An exception indicating an attempt to use an unbound namespace.
 */
@interface OFUnboundNamespaceException: OFException
{
	OFString *ns;
	OFString *prefix;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *namespace;
@property (readonly, nonatomic) OFString *prefix;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param ns The namespace which is unbound
 * \return A new unbound namespace exception
 */
+ newWithClass: (Class)class_
     namespace: (OFString*)ns;

/**
 * \param class_ The class of the object which caused the exception
 * \param prefix The prefix which is unbound
 * \return A new unbound namespace exception
 */
+ newWithClass: (Class)class_
	prefix: (OFString*)prefix;

/**
 * Initializes an already allocated unbound namespace failed exception
 *
 * \param class_ The class of the object which caused the exception
 * \param ns The namespace which is unbound
 * \return An initialized unbound namespace exception
 */
- initWithClass: (Class)class_
      namespace: (OFString*)ns;

/**
 * Initializes an already allocated unbound namespace failed exception
 *
 * \param class_ The class of the object which caused the exception
 * \param prefix The prefix which is unbound
 * \return An initialized unbound namespace exception
 */
- initWithClass: (Class)class_
	 prefix: (OFString*)prefix;

/**
 * \return The unbound namespace
 */
- (OFString*)namespace;

/**
 * \return The unbound prefix
 */
- (OFString*)prefix;
@end
