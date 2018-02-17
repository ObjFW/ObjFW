/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <errno.h>
#include <limits.h>

#include "unistd_wrapper.h"

#import "OFArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFLocalization.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFURL.h"
#import "OFURLHandler.h"

#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFCopyItemFailedException.h"
#import "OFGetCurrentDirectoryPathFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMoveItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFRemoveItemFailedException.h"
#import "OFRetrieveItemAttributesFailedException.h"
#import "OFUndefinedKeyException.h"
#import "OFUnsupportedProtocolException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
# include <ntdef.h>
#endif

#ifdef OF_MORPHOS
# define BOOL EXEC_BOOL
# include <proto/dos.h>
# include <proto/locale.h>
# undef BOOL
#endif

@interface OFFileManager_default: OFFileManager
@end

static OFFileManager *defaultManager;

const of_file_attribute_key_t of_file_attribute_key_size =
    @"of_file_attribute_key_size";
const of_file_attribute_key_t of_file_attribute_key_type =
    @"of_file_attribute_key_type";
const of_file_attribute_key_t of_file_attribute_key_posix_permissions =
    @"of_file_attribute_key_posix_permissions";
const of_file_attribute_key_t of_file_attribute_key_posix_uid =
    @"of_file_attribute_key_posix_uid";
const of_file_attribute_key_t of_file_attribute_key_posix_gid =
    @"of_file_attribute_key_posix_gid";
const of_file_attribute_key_t of_file_attribute_key_owner =
    @"of_file_attribute_key_owner";
const of_file_attribute_key_t of_file_attribute_key_group =
    @"of_file_attribute_key_group";
const of_file_attribute_key_t of_file_attribute_key_last_access_date =
    @"of_file_attribute_key_last_access_date";
const of_file_attribute_key_t of_file_attribute_key_modification_date =
    @"of_file_attribute_key_modification_date";
const of_file_attribute_key_t of_file_attribute_key_status_change_date =
    @"of_file_attribute_key_status_change_date";
const of_file_attribute_key_t of_file_attribute_key_symbolic_link_destination =
    @"of_file_attribute_key_symbolic_link_destination";

const of_file_type_t of_file_type_regular = @"of_file_type_regular";
const of_file_type_t of_file_type_directory = @"of_file_type_directory";
const of_file_type_t of_file_type_symbolic_link = @"of_file_type_symbolic_link";
const of_file_type_t of_file_type_fifo = @"of_file_type_fifo";
const of_file_type_t of_file_type_character_special =
    @"of_file_type_character_special";
const of_file_type_t of_file_type_block_special = @"of_file_type_block_special";
const of_file_type_t of_file_type_socket = @"of_file_type_socket";

#ifdef OF_MORPHOS
static bool dirChanged = false;
static BPTR originalDirLock = 0;

OF_DESTRUCTOR()
{
	if (dirChanged)
		UnLock(CurrentDir(originalDirLock));
}
#endif

static id
attributeForKeyOrException(of_file_attributes_t attributes,
    of_file_attribute_key_t key)
{
	id object = [attributes objectForKey: key];

	if (object == nil)
		@throw [OFUndefinedKeyException exceptionWithObject: attributes
								key: key];

	return object;
}

@implementation OFFileManager
+ (void)initialize
{
	if (self != [OFFileManager class])
		return;

	defaultManager = [[OFFileManager_default alloc] init];
}

+ (OFFileManager *)defaultManager
{
	return defaultManager;
}

- (OFString *)currentDirectoryPath
{
#if defined(OF_WINDOWS)
	OFString *ret;
	wchar_t *buffer = _wgetcwd(NULL, 0);

	@try {
		ret = [OFString stringWithUTF16String: buffer];
	} @finally {
		free(buffer);
	}

	return ret;
#elif defined(OF_MORPHOS)
	char buffer[512];

	if (!NameFromLock(((struct Process *)FindTask(NULL))->pr_CurrentDir,
	    buffer, 512)) {
		if (IoErr() == ERROR_LINE_TOO_LONG)
			@throw [OFOutOfRangeException exception];

		return nil;
	}

	return [OFString stringWithCString: buffer
				  encoding: [OFLocalization encoding]];
#else
	char buffer[PATH_MAX];

	if ((getcwd(buffer, PATH_MAX)) == NULL)
		@throw [OFGetCurrentDirectoryPathFailedException
		    exceptionWithErrNo: errno];

# ifdef OF_DJGPP
	/*
	 * For some reason, getcwd() returns forward slashes on DJGPP, even
	 * though the native format is to use backwards slashes.
	 */
	for (char *tmp = buffer; *tmp != '\0'; tmp++)
		if (*tmp == '/')
			*tmp = '\\';
# endif

	return [OFString stringWithCString: buffer
				  encoding: [OFLocalization encoding]];
#endif
}

- (OFURL *)currentDirectoryURL
{
	OFMutableURL *URL = [OFMutableURL URL];
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	[URL setScheme: @"file"];

#if OF_PATH_DELIMITER != '/'
	path = [[[self currentDirectoryPath] pathComponents]
	    componentsJoinedByString: @"/"];
#else
	path = [self currentDirectoryPath];
#endif

#ifndef OF_PATH_STARTS_WITH_SLASH
	path = [path stringByPrependingString: @"/"];
#endif

	[URL setPath: [path stringByAppendingString: @"/"]];

	[URL makeImmutable];

	objc_autoreleasePoolPop(pool);

	return URL;
}

- (of_file_attributes_t)attributesOfItemAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler attributesOfItemAtURL: URL];
}

- (of_file_attributes_t)attributesOfItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	of_file_attributes_t ret;

	ret = [self attributesOfItemAtURL: [OFURL fileURLWithPath: path]];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)setAttributes: (of_file_attributes_t)attributes
	  ofItemAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler setAttributes: attributes
		      ofItemAtURL: URL];
}

- (void)setAttributes: (of_file_attributes_t)attributes
	 ofItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self setAttributes: attributes
		ofItemAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);
}

- (bool)fileExistsAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler fileExistsAtURL: URL];
}

- (bool)fileExistsAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	ret = [self fileExistsAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)directoryExistsAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler directoryExistsAtURL: URL];
}

- (bool)directoryExistsAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	ret = [self directoryExistsAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)createDirectoryAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler createDirectoryAtURL: URL];
}

- (void)createDirectoryAtURL: (OFURL *)URL_
	       createParents: (bool)createParents
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableURL *URL = [[URL_ mutableCopy] autorelease];
	OFArray OF_GENERIC(OFString *) *components;
	OFString *currentPath = nil;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if (!createParents) {
		[self createDirectoryAtURL: URL];
		return;
	}

	components = [[URL URLEncodedPath] componentsSeparatedByString: @"/"];

	for (OFString *component in components) {
		if (currentPath != nil)
			currentPath = [currentPath
			    stringByAppendingFormat: @"/%@", component];
		else
			currentPath = component;

		[URL setURLEncodedPath: currentPath];

		if ([currentPath length] > 0 &&
		    ![self directoryExistsAtURL: URL])
			[self createDirectoryAtURL: URL];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)createDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self createDirectoryAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);
}

- (void)createDirectoryAtPath: (OFString *)path
		createParents: (bool)createParents
{
	void *pool = objc_autoreleasePoolPush();

	[self createDirectoryAtURL: [OFURL fileURLWithPath: path]
		     createParents: createParents];

	objc_autoreleasePoolPop(pool);
}

- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	return [URLHandler contentsOfDirectoryAtURL: URL];
}

- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFString *) *ret;

	ret = [self contentsOfDirectoryAtURL: [OFURL fileURLWithPath: path]];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)changeCurrentDirectoryPath: (OFString *)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#if defined(OF_WINDOWS)
	if (_wchdir([path UTF16String]) != 0)
		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errno];
#elif defined(OF_MORPHOS)
	BPTR lock, oldLock;

	if ((lock = Lock([path cStringWithEncoding: [OFLocalization encoding]],
	    SHARED_LOCK)) == 0) {
		int errNo;

		switch (IoErr()) {
		case ERROR_OBJECT_IN_USE:
		case ERROR_DISK_NOT_VALIDATED:
			errNo = EBUSY;
			break;
		case ERROR_OBJECT_NOT_FOUND:
			errNo = ENOENT;
			break;
		default:
			errNo = 0;
			break;
		}

		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errNo];
	}

	oldLock = CurrentDir(lock);

	if (!dirChanged)
		originalDirLock = oldLock;
	else
		UnLock(oldLock);

	dirChanged = true;
#else
	if (chdir([path cStringWithEncoding: [OFLocalization encoding]]) != 0)
		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errno];
#endif
}

- (void)changeCurrentDirectoryURL: (OFURL *)URL
{
	void *pool = objc_autoreleasePoolPush();

	[self changeCurrentDirectoryPath: [URL fileSystemRepresentation]];

	objc_autoreleasePoolPop(pool);
}

- (void)copyItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();

	[self copyItemAtURL: [OFURL fileURLWithPath: source]
		      toURL: [OFURL fileURLWithPath: destination]];

	objc_autoreleasePoolPop(pool);
}

- (void)copyItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination
{
	void *pool;
	OFURLHandler *URLHandler;
	of_file_attributes_t attributes;
	of_file_type_t type;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ((URLHandler = [OFURLHandler handlerForURL: source]) == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: source];

	if ([URLHandler copyItemAtURL: source
				toURL: destination])
		return;

	if ([self fileExistsAtURL: destination])
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EEXIST];

	@try {
		attributes = [self attributesOfItemAtURL: source];
	} @catch (OFRetrieveItemAttributesFailedException *e) {
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: [e errNo]];
	}

	type = [attributes fileType];

	if ([type isEqual: of_file_type_directory]) {
		OFArray *contents;

		@try {
			[self createDirectoryAtURL: destination];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
			of_file_attribute_key_t key =
			    of_file_attribute_key_posix_permissions;
			OFNumber *permissions = [attributes objectForKey: key];
			of_file_attributes_t destinationAttributes =
			    [OFDictionary dictionaryWithObject: permissions
							forKey: key];

			[self setAttributes: destinationAttributes
				ofItemAtURL: destination];
#endif

			contents = [self contentsOfDirectoryAtURL: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURL: source
					    destinationURL: destination
						     errNo: [e errNo]];

			@throw e;
		}

		for (OFString *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();
			OFURL *sourceURL, *destinationURL;

			sourceURL =
			    [source URLByAppendingPathComponent: item];
			destinationURL =
			    [destination URLByAppendingPathComponent: item];

			[self copyItemAtURL: sourceURL
				      toURL: destinationURL];

			objc_autoreleasePoolPop(pool2);
		}
	} else if ([type isEqual: of_file_type_regular]) {
		size_t pageSize = [OFSystemInfo pageSize];
		OFStream *sourceStream = nil;
		OFStream *destinationStream = nil;
		char *buffer;

		if ((buffer = malloc(pageSize)) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: pageSize];

		@try {
			sourceStream = [[OFURLHandler handlerForURL: source]
			    openItemAtURL: source
				     mode: @"r"];
			destinationStream = [[OFURLHandler handlerForURL:
			    destination] openItemAtURL: destination
						  mode: @"w"];

			while (![sourceStream isAtEndOfStream]) {
				size_t length;

				length = [sourceStream
				    readIntoBuffer: buffer
					    length: pageSize];
				[destinationStream writeBuffer: buffer
							length: length];
			}

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
			of_file_attribute_key_t key =
			    of_file_attribute_key_posix_permissions;
			OFNumber *permissions = [attributes objectForKey: key];
			of_file_attributes_t destinationAttributes =
			    [OFDictionary dictionaryWithObject: permissions
							forKey: key];

			[self setAttributes: destinationAttributes
				ofItemAtURL: destination];
#endif
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURL: source
					    destinationURL: destination
						     errNo: [e errNo]];

			@throw e;
		} @finally {
			[sourceStream close];
			[destinationStream close];
			free(buffer);
		}
#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
	} else if ([type isEqual: of_file_type_symbolic_link]) {
		@try {
			OFString *linkDestination =
			    [attributes fileSymbolicLinkDestination];

			[self createSymbolicLinkAtURL: destination
				  withDestinationPath: linkDestination];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURL: source
					    destinationURL: destination
						     errNo: [e errNo]];

			@throw e;
		}
#endif
	} else
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EINVAL];

	objc_autoreleasePoolPop(pool);
}

- (void)moveItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();

	[self moveItemAtURL: [OFURL fileURLWithPath: source]
		      toURL: [OFURL fileURLWithPath: destination]];

	objc_autoreleasePoolPop(pool);
}

- (void)moveItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination
{
	void *pool;
	OFURLHandler *URLHandler;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ((URLHandler = [OFURLHandler handlerForURL: source]) == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: source];

	@try {
		if ([URLHandler moveItemAtURL: source
					toURL: destination])
			return;
	} @catch (OFMoveItemFailedException *e) {
		if ([e errNo] != EXDEV)
			@throw e;
	}

	if ([self fileExistsAtURL: destination])
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: EEXIST];

	@try {
		[self copyItemAtURL: source
			      toURL: destination];
	} @catch (OFCopyItemFailedException *e) {
		[self removeItemAtURL: destination];

		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: [e errNo]];
	}

	@try {
		[self removeItemAtURL: source];
	} @catch (OFRemoveItemFailedException *e) {
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURL: source
			    destinationURL: destination
				     errNo: [e errNo]];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeItemAtURL: (OFURL *)URL
{
	OFURLHandler *URLHandler;

	if (URL == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URLHandler = [OFURLHandler handlerForURL: URL]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler removeItemAtURL: URL];
}

- (void)removeItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self removeItemAtURL: [OFURL fileURLWithPath: path]];

	objc_autoreleasePoolPop(pool);
}

- (void)linkItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination
{
	void *pool = objc_autoreleasePoolPush();
	OFURLHandler *URLHandler;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	if (![[destination scheme] isEqual: [source scheme]])
		@throw [OFInvalidArgumentException exception];

	URLHandler = [OFURLHandler handlerForURL: source];

	if (URLHandler == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURL: source];

	[URLHandler linkItemAtURL: source
			    toURL: destination];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
- (void)linkItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();

	[self linkItemAtURL: [OFURL fileURLWithPath: source]
		      toURL: [OFURL fileURLWithPath: destination]];

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)createSymbolicLinkAtURL: (OFURL *)URL
	    withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	OFURLHandler *URLHandler;

	if (URL == nil || target == nil)
		@throw [OFInvalidArgumentException exception];

	URLHandler = [OFURLHandler handlerForURL: URL];

	if (URLHandler == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	[URLHandler createSymbolicLinkAtURL: URL
			withDestinationPath: target];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
- (void)createSymbolicLinkAtPath: (OFString *)path
	     withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();

	[self createSymbolicLinkAtURL: [OFURL fileURLWithPath: path]
		  withDestinationPath: target];

	objc_autoreleasePoolPop(pool);
}
#endif
@end

@implementation OFDictionary (FileAttributes)
- (uintmax_t)fileSize
{
	return [attributeForKeyOrException(self, of_file_attribute_key_size)
	    uIntMaxValue];
}

- (of_file_type_t)fileType
{
	return attributeForKeyOrException(self, of_file_attribute_key_type);
}

- (uint16_t)filePOSIXPermissions
{
	return [attributeForKeyOrException(self,
	    of_file_attribute_key_posix_permissions) uInt16Value];
}

- (uint32_t)filePOSIXUID
{
	return [attributeForKeyOrException(self,
	    of_file_attribute_key_posix_uid) uInt32Value];
}

- (uint32_t)filePOSIXGID
{
	return [attributeForKeyOrException(self,
	    of_file_attribute_key_posix_gid) uInt32Value];
}

- (OFString *)fileOwner
{
	return attributeForKeyOrException(self, of_file_attribute_key_owner);
}

- (OFString *)fileGroup
{
	return attributeForKeyOrException(self, of_file_attribute_key_group);
}

- (OFDate *)fileLastAccessDate
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_last_access_date);
}

- (OFDate *)fileModificationDate
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_modification_date);
}

- (OFDate *)fileStatusChangeDate
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_status_change_date);
}

- (OFString *)fileSymbolicLinkDestination
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_symbolic_link_destination);
}
@end

@implementation OFFileManager_default
- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}
@end
