/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <dirent.h>
#include <unistd.h>

#ifdef HAVE_PWD_H
# include <pwd.h>
#endif
#ifdef HAVE_GRP_H
# include <grp.h>
#endif

#import "OFFileManager.h"
#import "OFFile.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFSystemInfo.h"

#ifdef OF_HAVE_THREADS
# import "threading.h"
#endif

#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFChangeOwnerFailedException.h"
#import "OFChangePermissionsFailedException.h"
#import "OFCopyItemFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkFailedException.h"
#import "OFLockFailedException.h"
#import "OFMoveItemFailedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"
#import "OFRemoveItemFailedException.h"
#import "OFStatItemFailedException.h"
#import "OFUnlockFailedException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
#endif

#ifndef S_IRGRP
# define S_IRGRP 0
#endif
#ifndef S_IROTH
# define S_IROTH 0
#endif
#ifndef S_IWGRP
# define S_IWGRP 0
#endif
#ifndef S_IWOTH
# define S_IWOTH 0
#endif

#define DEFAULT_MODE S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH
#define DIR_MODE DEFAULT_MODE | S_IXUSR | S_IXGRP | S_IXOTH

static OFFileManager *defaultManager;

#if defined(OF_HAVE_CHOWN) && defined(OF_HAVE_THREADS)
static of_mutex_t chownMutex;
#endif
#if !defined(HAVE_READDIR_R) && !defined(OF_WINDOWS) && defined(OF_HAVE_THREADS)
static of_mutex_t readdirMutex;
#endif

int
of_stat(OFString *path, of_stat_t *buffer)
{
#if defined(OF_WINDOWS)
	return _wstat64([path UTF16String], buffer);
#elif defined(OF_HAVE_OFF64_T)
	return stat64([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]], buffer);
#else
	return stat([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]], buffer);
#endif
}

int
of_lstat(OFString *path, of_stat_t *buffer)
{
#if defined(OF_WINDOWS)
	return _wstat64([path UTF16String], buffer);
#elif defined(HAVE_LSTAT)
# ifdef OF_HAVE_OFF64_T
	return lstat64([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]], buffer);
# else
	return lstat([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]], buffer);
# endif
#else
# ifdef OF_HAVE_OFF64_T
	return stat64([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]], buffer);
# else
	return stat([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]], buffer);
# endif
#endif
}

@implementation OFFileManager
+ (void)initialize
{
	if (self != [OFFileManager class])
		return;

	/*
	 * Make sure OFFile is initialized.
	 * On some systems, this is needed to initialize the file system driver.
	 */
	[OFFile class];

#if defined(OF_HAVE_CHOWN) && defined(OF_HAVE_THREADS)
	if (!of_mutex_new(&chownMutex))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif

#if !defined(HAVE_READDIR_R) && !defined(OF_WINDOWS) && defined(OF_HAVE_THREADS)
	if (!of_mutex_new(&readdirMutex))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif

	defaultManager = [[OFFileManager alloc] init];
}

+ (OFFileManager*)defaultManager
{
	return defaultManager;
}

- (OFString*)currentDirectoryPath
{
	OFString *ret;
#ifndef OF_WINDOWS
	char *buffer = getcwd(NULL, 0);
#else
	wchar_t *buffer = _wgetcwd(NULL, 0);
#endif

	@try {
#ifndef OF_WINDOWS
		ret = [OFString
		    stringWithCString: buffer
			     encoding: [OFSystemInfo native8BitEncoding]];
#else
		ret = [OFString stringWithUTF16String: buffer];
#endif
	} @finally {
		free(buffer);
	}

	return ret;
}

- (bool)fileExistsAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) == -1)
		return false;

	if (S_ISREG(s.st_mode))
		return true;

	return false;
}

- (bool)directoryExistsAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) == -1)
		return false;

	if (S_ISDIR(s.st_mode))
		return true;

	return false;
}

#ifdef OF_HAVE_SYMLINK
- (bool)symbolicLinkExistsAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_lstat(path, &s) == -1)
		return false;

	if (S_ISLNK(s.st_mode))
		return true;

	return false;
}
#endif

- (void)createDirectoryAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef OF_WINDOWS
	if (mkdir([path cStringWithEncoding: [OFSystemInfo native8BitEncoding]],
	    DIR_MODE) != 0)
#else
	if (_wmkdir([path UTF16String]) != 0)
#endif
		@throw [OFCreateDirectoryFailedException
		    exceptionWithPath: path
				errNo: errno];
}

- (void)createDirectoryAtPath: (OFString*)path
		createParents: (bool)createParents
{
	void *pool;
	OFArray *pathComponents;
	OFString *currentPath = nil, *component;
	OFEnumerator *enumerator;

	if (!createParents) {
		[self createDirectoryAtPath: path];
		return;
	}

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	pathComponents = [path pathComponents];
	enumerator = [pathComponents objectEnumerator];
	while ((component = [enumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		if (currentPath != nil)
			currentPath = [currentPath
			    stringByAppendingPathComponent: component];
		else
			currentPath = component;

		if ([currentPath length] > 0 &&
		    ![self directoryExistsAtPath: currentPath])
			[self createDirectoryAtPath: currentPath];

		[currentPath retain];

		objc_autoreleasePoolPop(pool2);

		[currentPath autorelease];
	}

	objc_autoreleasePoolPop(pool);
}

- (OFArray*)contentsOfDirectoryAtPath: (OFString*)path
{
	OFMutableArray *files;
#ifndef OF_WINDOWS
	of_string_encoding_t encoding;
#endif

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	files = [OFMutableArray array];

#ifndef OF_WINDOWS
	DIR *dir;

	encoding = [OFSystemInfo native8BitEncoding];

	if ((dir = opendir([path cStringWithEncoding: encoding])) == NULL)
		@throw [OFOpenItemFailedException exceptionWithPath: path
							      errNo: errno];

# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
	if (!of_mutex_lock(&readdirMutex))
		@throw [OFLockFailedException exception];
# endif

	@try {
		for (;;) {
			struct dirent *dirent;
# ifdef HAVE_READDIR_R
			struct dirent buffer;
# endif
			void *pool;
			OFString *file;

# ifdef HAVE_READDIR_R
			if (readdir_r(dir, &buffer, &dirent) != 0)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: errno];

			if (dirent == NULL)
				break;
# else
			if ((dirent = readdir(dir)) == NULL) {
				if (errno == 0)
					break;
				else
					@throw [OFReadFailedException
					    exceptionWithObject: self
						requestedLength: 0
							  errNo: errno];
			}
# endif

			if (strcmp(dirent->d_name, ".") == 0 ||
			    strcmp(dirent->d_name, "..") == 0)
				continue;

			pool = objc_autoreleasePoolPush();

			file = [OFString stringWithCString: dirent->d_name
						  encoding: encoding];
			[files addObject: file];

			objc_autoreleasePoolPop(pool);
		}
	} @finally {
		closedir(dir);
# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
		if (!of_mutex_unlock(&readdirMutex))
			@throw [OFUnlockFailedException exception];
# endif
	}
#else
	void *pool = objc_autoreleasePoolPush();
	HANDLE handle;
	WIN32_FIND_DATAW fd;

	path = [path stringByAppendingString: @"\\*"];

	if ((handle = FindFirstFileW([path UTF16String],
	    &fd)) == INVALID_HANDLE_VALUE) {
		int errNo = 0;

		if (GetLastError() == ERROR_FILE_NOT_FOUND)
			errNo = ENOENT;

		@throw [OFOpenItemFailedException exceptionWithPath: path
							      errNo: errNo];
	}

	@try {
		do {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *file;

			if (!wcscmp(fd.cFileName, L".") ||
			    !wcscmp(fd.cFileName, L".."))
				continue;

			file = [OFString stringWithUTF16String: fd.cFileName];
			[files addObject: file];

			objc_autoreleasePoolPop(pool2);
		} while (FindNextFileW(handle, &fd));

		if (GetLastError() != ERROR_NO_MORE_FILES)
			@throw [OFReadFailedException exceptionWithObject: self
							  requestedLength: 0];
	} @finally {
		FindClose(handle);
	}

	objc_autoreleasePoolPop(pool);
#endif

	[files makeImmutable];

	return files;
}

- (void)changeCurrentDirectoryPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef OF_WINDOWS
	if (chdir([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]]) != 0)
#else
	if (_wchdir([path UTF16String]) != 0)
#endif
		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errno];
}

- (of_offset_t)sizeOfFileAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	return s.st_size;
}

- (OFDate*)accessTimeOfItemAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_atime];
}

- (OFDate*)modificationTimeOfItemAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_mtime];
}

- (OFDate*)statusChangeTimeOfItemAtPath: (OFString*)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_ctime];
}

#ifdef OF_HAVE_CHMOD
- (void)changePermissionsOfItemAtPath: (OFString*)path
			  permissions: (mode_t)permissions
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

# ifndef OF_WINDOWS
	if (chmod([path cStringWithEncoding: [OFSystemInfo native8BitEncoding]],
	    permissions) != 0)
# else
	if (_wchmod([path UTF16String], permissions) != 0)
# endif
		@throw [OFChangePermissionsFailedException
		    exceptionWithPath: path
			  permissions: permissions
				errNo: errno];
}
#endif

#ifdef OF_HAVE_CHOWN
- (void)changeOwnerOfItemAtPath: (OFString*)path
			  owner: (OFString*)owner
			  group: (OFString*)group
{
	uid_t uid = -1;
	gid_t gid = -1;
	of_string_encoding_t encoding;

	if (path == nil || (owner == nil && group == nil))
		@throw [OFInvalidArgumentException exception];

	encoding = [OFSystemInfo native8BitEncoding];

# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&chownMutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFChangeOwnerFailedException
				    exceptionWithPath: path
						owner: owner
						group: group
						errNo: errno];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFChangeOwnerFailedException
				    exceptionWithPath: path
						owner: owner
						group: group
						errNo: errno];

			gid = group_->gr_gid;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&chownMutex))
			@throw [OFUnlockFailedException exception];
	}
# endif

	if (chown([path cStringWithEncoding: encoding], uid, gid) != 0)
		@throw [OFChangeOwnerFailedException exceptionWithPath: path
								 owner: owner
								 group: group
								 errNo: errno];
}
#endif

- (void)copyItemAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool;
	of_stat_t s;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (of_lstat(destination, &s) == 0)
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: EEXIST];

	if (of_lstat(source, &s) != 0)
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: errno];

	if (S_ISDIR(s.st_mode)) {
		OFArray *contents;
		OFEnumerator *enumerator;
		OFString *item;

		@try {
			[self createDirectoryAtPath: destination];
#ifdef OF_HAVE_CHMOD
			[self changePermissionsOfItemAtPath: destination
						permissions: s.st_mode];
#endif

			contents = [self contentsOfDirectoryAtPath: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourcePath: source
					    destinationPath: destination
						      errNo: [e errNo]];

			@throw e;
		}

		enumerator = [contents objectEnumerator];
		while ((item = [enumerator nextObject]) != nil) {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *sourcePath, *destinationPath;

			sourcePath =
			    [source stringByAppendingPathComponent: item];
			destinationPath =
			    [destination stringByAppendingPathComponent: item];

			[self copyItemAtPath: sourcePath
				      toPath: destinationPath];

			objc_autoreleasePoolPop(pool2);
		}
	} else if (S_ISREG(s.st_mode)) {
		size_t pageSize = [OFSystemInfo pageSize];
		OFFile *sourceFile = nil;
		OFFile *destinationFile = nil;
		char *buffer;

		if ((buffer = malloc(pageSize)) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: pageSize];

		@try {
			sourceFile = [OFFile fileWithPath: source
						     mode: @"rb"];
			destinationFile = [OFFile fileWithPath: destination
							  mode: @"wb"];

			while (![sourceFile isAtEndOfStream]) {
				size_t length;

				length = [sourceFile readIntoBuffer: buffer
							     length: pageSize];
				[destinationFile writeBuffer: buffer
						      length: length];
			}

#ifdef OF_HAVE_CHMOD
			[self changePermissionsOfItemAtPath: destination
						permissions: s.st_mode];
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
				    exceptionWithSourcePath: source
					    destinationPath: destination
						      errNo: [e errNo]];

			@throw e;
		} @finally {
			[sourceFile close];
			[destinationFile close];
			free(buffer);
		}
#ifdef OF_HAVE_SYMLINK
	} else if (S_ISLNK(s.st_mode)) {
		@try {
			source = [self destinationOfSymbolicLinkAtPath: source];

			[self createSymbolicLinkAtPath: destination
				   withDestinationPath: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourcePath: source
					    destinationPath: destination
						      errNo: [e errNo]];

			@throw e;
		}
#endif
	} else
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: ENOTSUP];

	objc_autoreleasePoolPop(pool);
}

- (void)moveItemAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool;
	of_stat_t s;
#ifndef OF_WINDOWS
	of_string_encoding_t encoding;
#endif

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (of_lstat(destination, &s) == 0)
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: EEXIST];

#ifndef OF_WINDOWS
	encoding = [OFSystemInfo native8BitEncoding];

	if (rename([source cStringWithEncoding: encoding],
	    [destination cStringWithEncoding: encoding]) != 0) {
#else
	if (_wrename([source UTF16String], [destination UTF16String]) != 0) {
#endif
		if (errno != EXDEV)
			@throw [OFMoveItemFailedException
			    exceptionWithSourcePath: source
				    destinationPath: destination
					      errNo: errno];

		@try {
			[self copyItemAtPath: source
				      toPath: destination];
		} @catch (OFCopyItemFailedException *e) {
			[self removeItemAtPath: destination];

			@throw [OFMoveItemFailedException
			    exceptionWithSourcePath: source
				    destinationPath: destination
					      errNo: [e errNo]];
		}

		@try {
			[self removeItemAtPath: source];
		} @catch (OFRemoveItemFailedException *e) {
			@throw [OFMoveItemFailedException
			    exceptionWithSourcePath: source
				    destinationPath: destination
					      errNo: [e errNo]];
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeItemAtPath: (OFString*)path
{
	void *pool;
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (of_lstat(path, &s) != 0)
		@throw [OFRemoveItemFailedException exceptionWithPath: path
								errNo: errno];

	if (S_ISDIR(s.st_mode)) {
		OFArray *contents;
		OFEnumerator *enumerator;
		OFString *item;

		@try {
			contents = [self contentsOfDirectoryAtPath: path];
		} @catch (id e) {
			/*
			 * Only convert exceptions to
			 * OFRemoveItemFailedException that have an errNo
			 * property. This covers all I/O related exceptions
			 * from the operations used to remove an item, all
			 * others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFRemoveItemFailedException
				    exceptionWithPath: path
						errNo: [e errNo]];

			@throw e;
		}

		enumerator = [contents objectEnumerator];
		while ((item = [enumerator nextObject]) != nil) {
			void *pool2 = objc_autoreleasePoolPush();

			[self removeItemAtPath:
			    [path stringByAppendingPathComponent: item]];

			objc_autoreleasePoolPop(pool2);
		}
	}

#ifndef OF_WINDOWS
	if (remove([path cStringWithEncoding:
	    [OFSystemInfo native8BitEncoding]]) != 0)
#else
	if (_wremove([path UTF16String]) != 0)
#endif
		@throw [OFRemoveItemFailedException exceptionWithPath: path
								errNo: errno];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_LINK
- (void)linkItemAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool;
	of_string_encoding_t encoding;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	encoding = [OFSystemInfo native8BitEncoding];

	if (link([source cStringWithEncoding: encoding],
	    [destination cStringWithEncoding: encoding]) != 0)
		@throw [OFLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: errno];

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_HAVE_SYMLINK
- (void)createSymbolicLinkAtPath: (OFString*)destination
	     withDestinationPath: (OFString*)source
{
	void *pool;
	of_string_encoding_t encoding;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	encoding = [OFSystemInfo native8BitEncoding];

	if (symlink([source cStringWithEncoding: encoding],
	    [destination cStringWithEncoding: encoding]) != 0)
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: errno];

	objc_autoreleasePoolPop(pool);
}

- (OFString*)destinationOfSymbolicLinkAtPath: (OFString*)path
{
	char destination[PATH_MAX];
	ssize_t length;
	of_string_encoding_t encoding;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	encoding = [OFSystemInfo native8BitEncoding];
	length = readlink([path cStringWithEncoding: encoding],
	    destination, PATH_MAX);

	if (length < 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	return [OFString stringWithCString: destination
				  encoding: encoding
				    length: length];
}
#endif
@end
