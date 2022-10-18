/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#define OF_FILE_MANAGER_M

#include <errno.h>
#include <limits.h>
#include "unistd_wrapper.h"

#import "platform.h"

#ifdef OF_PSP
# include <sys/syslimits.h>
#endif

#import "OFArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFURI.h"
#import "OFURIHandler.h"

#import "OFChangeCurrentDirectoryFailedException.h"
#import "OFCopyItemFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFGetCurrentDirectoryFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMoveItemFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFRemoveItemFailedException.h"
#import "OFGetItemAttributesFailedException.h"
#import "OFUndefinedKeyException.h"
#import "OFUnsupportedProtocolException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
# include <ntdef.h>
#endif

#ifdef OF_AMIGAOS
# include <proto/exec.h>
# include <proto/dos.h>
#endif

#ifdef OF_MINT
# include <bits/local_lim.h>
#endif

@interface OFDefaultFileManager: OFFileManager
@end

#ifdef OF_AMIGAOS4
# define CurrentDir(lock) SetCurrentDir(lock)
#endif

#include "OFFileManagerConstants.inc"

static OFFileManager *defaultManager;

#ifdef OF_AMIGAOS
static bool dirChanged = false;
static BPTR originalDirLock = 0;

OF_DESTRUCTOR()
{
	if (dirChanged)
		UnLock(CurrentDir(originalDirLock));
}
#endif

static id
attributeForKeyOrException(OFFileAttributes attributes, OFFileAttributeKey key)
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

#ifdef OF_HAVE_FILES
	/*
	 * Make sure OFFile is initialized.
	 * On some systems, this is needed to initialize the file system driver.
	 */
	[OFFile class];
#endif

	defaultManager = [[OFDefaultFileManager alloc] init];
}

+ (OFFileManager *)defaultManager
{
	return defaultManager;
}

#ifdef OF_HAVE_FILES
- (OFString *)currentDirectoryPath
{
# if defined(OF_WINDOWS)
	OFString *ret;

	if ([OFSystemInfo isWindowsNT]) {
		wchar_t *buffer = _wgetcwd(NULL, 0);

		@try {
			ret = [OFString stringWithUTF16String: buffer];
		} @finally {
			free(buffer);
		}
	} else {
		char *buffer = _getcwd(NULL, 0);

		@try {
			ret = [OFString stringWithCString: buffer
						 encoding: [OFLocale encoding]];
		} @finally {
			free(buffer);
		}
	}

	return ret;
# elif defined(OF_AMIGAOS)
	char buffer[512];

	if (!NameFromLock(((struct Process *)FindTask(NULL))->pr_CurrentDir,
	    buffer, 512)) {
		if (IoErr() == ERROR_LINE_TOO_LONG)
			@throw [OFOutOfRangeException exception];

		return nil;
	}

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]];
# else
	char buffer[PATH_MAX];

	if ((getcwd(buffer, PATH_MAX)) == NULL)
		@throw [OFGetCurrentDirectoryFailedException
		    exceptionWithErrNo: errno];

#  ifdef OF_DJGPP
	/*
	 * For some reason, getcwd() returns forward slashes on DJGPP, even
	 * though the native format is to use backwards slashes.
	 */
	for (char *tmp = buffer; *tmp != '\0'; tmp++)
		if (*tmp == '/')
			*tmp = '\\';
#  endif

	return [OFString stringWithCString: buffer
				  encoding: [OFLocale encoding]];
# endif
}

- (OFURI *)currentDirectoryURI
{
	void *pool = objc_autoreleasePoolPush();
	OFURI *ret;

	ret = [OFURI fileURIWithPath: self.currentDirectoryPath];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}
#endif

- (OFFileAttributes)attributesOfItemAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	return [URIHandler attributesOfItemAtURI: URI];
}

#ifdef OF_HAVE_FILES
- (OFFileAttributes)attributesOfItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFileAttributes ret;

	ret = [self attributesOfItemAtURI: [OFURI fileURIWithPath: path]];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
#endif

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	[URIHandler setAttributes: attributes ofItemAtURI: URI];
}

#ifdef OF_HAVE_FILES
- (void)setAttributes: (OFFileAttributes)attributes
	 ofItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	[self setAttributes: attributes
		ofItemAtURI: [OFURI fileURIWithPath: path]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (bool)fileExistsAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	return [URIHandler fileExistsAtURI: URI];
}

#ifdef OF_HAVE_FILES
- (bool)fileExistsAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	ret = [self fileExistsAtURI: [OFURI fileURIWithPath: path]];

	objc_autoreleasePoolPop(pool);

	return ret;
}
#endif

- (bool)directoryExistsAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	return [URIHandler directoryExistsAtURI: URI];
}

#ifdef OF_HAVE_FILES
- (bool)directoryExistsAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	ret = [self directoryExistsAtURI: [OFURI fileURIWithPath: path]];

	objc_autoreleasePoolPop(pool);

	return ret;
}
#endif

- (void)createDirectoryAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	[URIHandler createDirectoryAtURI: URI];
}

- (void)createDirectoryAtURI: (OFURI *)URI createParents: (bool)createParents
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableURI *mutableURI;
	OFArray OF_GENERIC(OFString *) *components;
	OFMutableArray OF_GENERIC(OFURI *) *componentURIs;
	size_t componentURIsCount;
	ssize_t i;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if (!createParents) {
		[self createDirectoryAtURI: URI];
		return;
	}

	/*
	 * Try blindly creating the directory first.
	 *
	 * The reason for this is that we might be sandboxed, so attempting to
	 * create any of the parent directories will fail, while creating the
	 * directory itself will work.
	 */
	if ([self directoryExistsAtURI: URI])
		return;

	@try {
		[self createDirectoryAtURI: URI];
		return;
	} @catch (OFCreateDirectoryFailedException *e) {
		/*
		 * If we didn't fail because any of the parents is missing,
		 * there is no point in trying to create the parents.
		 */
		if (e.errNo != ENOENT)
			@throw e;
	}

	/*
	 * Because we might be sandboxed (and for remote URIs don't even know
	 * anything at all), we generate the URI for every component. We then
	 * iterate them in reverse order until we find the first existing
	 * directory, and then create subdirectories from there.
	 */
	mutableURI = [[URI mutableCopy] autorelease];
	mutableURI.percentEncodedPath = @"/";
	components = URI.pathComponents;
	componentURIs = [OFMutableArray arrayWithCapacity: components.count];

	for (OFString *component in components) {
		[mutableURI appendPathComponent: component];

		if (![mutableURI.percentEncodedPath isEqual: @"/"])
			[componentURIs addObject:
			    [[mutableURI copy] autorelease]];
	}

	componentURIsCount = componentURIs.count;
	for (i = componentURIsCount - 1; i > 0; i--) {
		if ([self directoryExistsAtURI:
		    [componentURIs objectAtIndex: i]])
			break;
	}

	if (++i == (ssize_t)componentURIsCount) {
		/*
		 * The URI exists, even though before we made sure it did not.
		 * That means it was created in the meantime by something else,
		 * so we're done here.
		 */
		objc_autoreleasePoolPop(pool);
		return;
	}

	for (; i < (ssize_t)componentURIsCount; i++)
		[self createDirectoryAtURI: [componentURIs objectAtIndex: i]];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_FILES
- (void)createDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	[self createDirectoryAtURI: [OFURI fileURIWithPath: path]];

	objc_autoreleasePoolPop(pool);
}

- (void)createDirectoryAtPath: (OFString *)path
		createParents: (bool)createParents
{
	void *pool = objc_autoreleasePoolPush();

	[self createDirectoryAtURI: [OFURI fileURIWithPath: path]
		     createParents: createParents];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFArray OF_GENERIC(OFURI *) *)contentsOfDirectoryAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	return [URIHandler contentsOfDirectoryAtURI: URI];
}

#ifdef OF_HAVE_FILES
- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFURI *) *URIs;
	OFMutableArray OF_GENERIC(OFString *) *ret;

	URIs = [self contentsOfDirectoryAtURI: [OFURI fileURIWithPath: path]];
	ret = [OFMutableArray arrayWithCapacity: URIs.count];

	for (OFURI *URI in URIs)
		[ret addObject: URI.lastPathComponent];

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFArray OF_GENERIC(OFString *) *)subpathsOfDirectoryAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray OF_GENERIC(OFString *) *ret =
	    [OFMutableArray arrayWithObject: path];

	for (OFString *subpath in [self contentsOfDirectoryAtPath: path]) {
		void *pool2 = objc_autoreleasePoolPush();
		OFString *fullSubpath =
		    [path stringByAppendingPathComponent: subpath];
		OFFileAttributes attributes =
		    [self attributesOfItemAtPath: fullSubpath];

		if ([attributes.fileType isEqual: OFFileTypeDirectory])
			[ret addObjectsFromArray:
			    [self subpathsOfDirectoryAtPath: fullSubpath]];
		else
			[ret addObject: fullSubpath];

		objc_autoreleasePoolPop(pool2);
	}

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)changeCurrentDirectoryPath: (OFString *)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

# ifdef OF_AMIGAOS
	BPTR lock, oldLock;

	if ((lock = Lock([path cStringWithEncoding: [OFLocale encoding]],
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

		@throw [OFChangeCurrentDirectoryFailedException
		    exceptionWithPath: path
				errNo: errNo];
	}

	oldLock = CurrentDir(lock);

	if (!dirChanged)
		originalDirLock = oldLock;
	else
		UnLock(oldLock);

	dirChanged = true;
# else
	int status;

#  ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT])
		status = _wchdir(path.UTF16String);
	else
#  endif
		status = chdir(
		    [path cStringWithEncoding: [OFLocale encoding]]);

	if (status != 0)
		@throw [OFChangeCurrentDirectoryFailedException
		    exceptionWithPath: path
				errNo: errno];
# endif
}

- (void)changeCurrentDirectoryURI: (OFURI *)URI
{
	void *pool = objc_autoreleasePoolPush();

	[self changeCurrentDirectoryPath: URI.fileSystemRepresentation];

	objc_autoreleasePoolPop(pool);
}

- (void)copyItemAtPath: (OFString *)source toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();

	[self copyItemAtURI: [OFURI fileURIWithPath: source]
		      toURI: [OFURI fileURIWithPath: destination]];

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)copyItemAtURI: (OFURI *)source toURI: (OFURI *)destination
{
	void *pool;
	OFURIHandler *URIHandler;
	OFFileAttributes attributes;
	OFFileAttributeType type;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ((URIHandler = [OFURIHandler handlerForURI: source]) == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURI: source];

	if ([URIHandler copyItemAtURI: source toURI: destination])
		return;

	if ([self fileExistsAtURI: destination])
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURI: source
			    destinationURI: destination
				     errNo: EEXIST];

	@try {
		attributes = [self attributesOfItemAtURI: source];
	} @catch (OFGetItemAttributesFailedException *e) {
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURI: source
			    destinationURI: destination
				     errNo: e.errNo];
	}

	type = attributes.fileType;

	if ([type isEqual: OFFileTypeDirectory]) {
		OFArray OF_GENERIC(OFURI *) *contents;

		@try {
			[self createDirectoryAtURI: destination];

			@try {
				OFFileAttributeKey key = OFFilePOSIXPermissions;
				OFNumber *permissions =
				    [attributes objectForKey: key];
				OFFileAttributes destinationAttributes;

				if (permissions != nil) {
					destinationAttributes = [OFDictionary
					    dictionaryWithObject: permissions
							  forKey: key];
					[self
					    setAttributes: destinationAttributes
					      ofItemAtURI: destination];
				}
			} @catch (OFNotImplementedException *e) {
			}

			contents = [self contentsOfDirectoryAtURI: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURI: source
					    destinationURI: destination
						     errNo: [e errNo]];

			@throw e;
		}

		for (OFURI *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();
			OFURI *destinationURI = [destination
			    URIByAppendingPathComponent:
			    item.lastPathComponent];

			[self copyItemAtURI: item toURI: destinationURI];

			objc_autoreleasePoolPop(pool2);
		}
	} else if ([type isEqual: OFFileTypeRegular]) {
		size_t pageSize = [OFSystemInfo pageSize];
		OFStream *sourceStream = nil;
		OFStream *destinationStream = nil;
		char *buffer;

		buffer = OFAllocMemory(1, pageSize);
		@try {
			sourceStream = [OFURIHandler openItemAtURI: source
							      mode: @"r"];
			destinationStream = [OFURIHandler
			    openItemAtURI: destination
				     mode: @"w"];

			while (!sourceStream.atEndOfStream) {
				size_t length;

				length = [sourceStream
				    readIntoBuffer: buffer
					    length: pageSize];
				[destinationStream writeBuffer: buffer
							length: length];
			}

			@try {
				OFFileAttributeKey key = OFFilePOSIXPermissions;
				OFNumber *permissions = [attributes
				    objectForKey: key];
				OFFileAttributes destinationAttributes;

				if (permissions != nil) {
					destinationAttributes = [OFDictionary
					    dictionaryWithObject: permissions
							  forKey: key];
					[self
					    setAttributes: destinationAttributes
					      ofItemAtURI: destination];
				}
			} @catch (OFNotImplementedException *e) {
			}
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourceURI: source
					    destinationURI: destination
						     errNo: [e errNo]];

			@throw e;
		} @finally {
			[sourceStream close];
			[destinationStream close];
			OFFreeMemory(buffer);
		}
	} else if ([type isEqual: OFFileTypeSymbolicLink]) {
		@try {
			OFString *linkDestination =
			    attributes.fileSymbolicLinkDestination;

			[self createSymbolicLinkAtURI: destination
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
				    exceptionWithSourceURI: source
					    destinationURI: destination
						     errNo: [e errNo]];

			@throw e;
		}
	} else
		@throw [OFCopyItemFailedException
		    exceptionWithSourceURI: source
			    destinationURI: destination
				     errNo: EINVAL];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_FILES
- (void)moveItemAtPath: (OFString *)source toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();
	[self moveItemAtURI: [OFURI fileURIWithPath: source]
		      toURI: [OFURI fileURIWithPath: destination]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)moveItemAtURI: (OFURI *)source toURI: (OFURI *)destination
{
	void *pool;
	OFURIHandler *URIHandler;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ((URIHandler = [OFURIHandler handlerForURI: source]) == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURI: source];

	@try {
		if ([URIHandler moveItemAtURI: source toURI: destination])
			return;
	} @catch (OFMoveItemFailedException *e) {
		if (e.errNo != EXDEV)
			@throw e;
	}

	if ([self fileExistsAtURI: destination])
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURI: source
			    destinationURI: destination
				     errNo: EEXIST];

	@try {
		[self copyItemAtURI: source toURI: destination];
	} @catch (OFCopyItemFailedException *e) {
		[self removeItemAtURI: destination];

		@throw [OFMoveItemFailedException
		    exceptionWithSourceURI: source
			    destinationURI: destination
				     errNo: e.errNo];
	}

	@try {
		[self removeItemAtURI: source];
	} @catch (OFRemoveItemFailedException *e) {
		@throw [OFMoveItemFailedException
		    exceptionWithSourceURI: source
			    destinationURI: destination
				     errNo: e.errNo];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeItemAtURI: (OFURI *)URI
{
	OFURIHandler *URIHandler;

	if (URI == nil)
		@throw [OFInvalidArgumentException exception];

	if ((URIHandler = [OFURIHandler handlerForURI: URI]) == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	[URIHandler removeItemAtURI: URI];
}

#ifdef OF_HAVE_FILES
- (void)removeItemAtPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	[self removeItemAtURI: [OFURI fileURIWithPath: path]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)linkItemAtURI: (OFURI *)source toURI: (OFURI *)destination
{
	void *pool = objc_autoreleasePoolPush();
	OFURIHandler *URIHandler;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	if (![destination.scheme isEqual: source.scheme])
		@throw [OFInvalidArgumentException exception];

	URIHandler = [OFURIHandler handlerForURI: source];

	if (URIHandler == nil)
		@throw [OFUnsupportedProtocolException
		    exceptionWithURI: source];

	[URIHandler linkItemAtURI: source toURI: destination];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
- (void)linkItemAtPath: (OFString *)source toPath: (OFString *)destination
{
	void *pool = objc_autoreleasePoolPush();
	[self linkItemAtURI: [OFURI fileURIWithPath: source]
		      toURI: [OFURI fileURIWithPath: destination]];
	objc_autoreleasePoolPop(pool);
}
#endif

- (void)createSymbolicLinkAtURI: (OFURI *)URI
	    withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	OFURIHandler *URIHandler;

	if (URI == nil || target == nil)
		@throw [OFInvalidArgumentException exception];

	URIHandler = [OFURIHandler handlerForURI: URI];

	if (URIHandler == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	[URIHandler createSymbolicLinkAtURI: URI withDestinationPath: target];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
- (void)createSymbolicLinkAtPath: (OFString *)path
	     withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	[self createSymbolicLinkAtURI: [OFURI fileURIWithPath: path]
		  withDestinationPath: target];
	objc_autoreleasePoolPop(pool);
}
#endif
@end

@implementation OFDefaultFileManager
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
	return OFMaxRetainCount;
}
@end

@implementation OFDictionary (FileAttributes)
- (unsigned long long)fileSize
{
	return [attributeForKeyOrException(self, OFFileSize)
	    unsignedLongLongValue];
}

- (OFFileAttributeType)fileType
{
	return attributeForKeyOrException(self, OFFileType);
}

- (unsigned long)filePOSIXPermissions
{
	return [attributeForKeyOrException(self,
	    OFFilePOSIXPermissions) unsignedLongValue];
}

- (unsigned long)fileOwnerAccountID
{
	return [attributeForKeyOrException(self,
	    OFFileOwnerAccountID) unsignedLongValue];
}

- (unsigned long)fileGroupOwnerAccountID
{
	return [attributeForKeyOrException(self,
	    OFFileGroupOwnerAccountID) unsignedLongValue];
}

- (OFString *)fileOwnerAccountName
{
	return attributeForKeyOrException(self, OFFileOwnerAccountName);
}

- (OFString *)fileGroupOwnerAccountName
{
	return attributeForKeyOrException(self, OFFileGroupOwnerAccountName);
}

- (OFDate *)fileLastAccessDate
{
	return attributeForKeyOrException(self, OFFileLastAccessDate);
}

- (OFDate *)fileModificationDate
{
	return attributeForKeyOrException(self, OFFileModificationDate);
}

- (OFDate *)fileStatusChangeDate
{
	return attributeForKeyOrException(self, OFFileStatusChangeDate);
}

- (OFDate *)fileCreationDate
{
	return attributeForKeyOrException(self, OFFileCreationDate);
}

- (OFString *)fileSymbolicLinkDestination
{
	return attributeForKeyOrException(self, OFFileSymbolicLinkDestination);
}
@end
