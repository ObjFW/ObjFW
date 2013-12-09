/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#define __NO_EXT_QNX

/* Work around a bug with Clang + glibc */
#ifdef __clang__
# define _HAVE_STRING_ARCH_strcmp
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>

#ifdef HAVE_PWD_H
# include <pwd.h>
#endif
#ifdef HAVE_GRP_H
# include <grp.h>
#endif

#ifdef __wii__
# define BOOL OGC_BOOL
# include <fat.h>
# undef BOOL
#endif

#import "OFFile.h"
#import "OFString.h"
#import "OFArray.h"
#ifdef OF_HAVE_THREADS
# import "threading.h"
#endif
#import "OFDate.h"
#import "OFSystemInfo.h"

#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFChangeOwnerFailedException.h"
#import "OFChangePermissionsFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkFailedException.h"
#import "OFLockFailedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"
#import "OFRemoveItemFailedException.h"
#import "OFRenameItemFailedException.h"
#import "OFSeekFailedException.h"
#import "OFUnlockFailedException.h"
#import "OFWriteFailedException.h"

#import "autorelease.h"
#import "macros.h"

#ifdef _WIN32
# include <windows.h>
# include <wchar.h>
#endif

#ifndef O_BINARY
# define O_BINARY 0
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

#if defined(OF_HAVE_CHOWN) && defined(OF_HAVE_THREADS)
static of_mutex_t mutex;
#endif

static int
parseMode(const char *mode)
{
	if (!strcmp(mode, "r"))
		return O_RDONLY;
	if (!strcmp(mode, "rb"))
		return O_RDONLY | O_BINARY;
	if (!strcmp(mode, "r+"))
		return O_RDWR;
	if (!strcmp(mode, "rb+") || !strcmp(mode, "r+b"))
		return O_RDWR | O_BINARY;
	if (!strcmp(mode, "w"))
		return O_WRONLY | O_CREAT | O_TRUNC;
	if (!strcmp(mode, "wb"))
		return O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
	if (!strcmp(mode, "w+"))
		return O_RDWR | O_CREAT | O_TRUNC;
	if (!strcmp(mode, "wb+") || !strcmp(mode, "w+b"))
		return O_RDWR | O_CREAT | O_TRUNC | O_BINARY;
	if (!strcmp(mode, "a"))
		return O_WRONLY | O_CREAT | O_APPEND;
	if (!strcmp(mode, "ab"))
		return O_WRONLY | O_CREAT | O_APPEND | O_BINARY;
	if (!strcmp(mode, "a+"))
		return O_RDWR | O_CREAT | O_APPEND;
	if (!strcmp(mode, "ab+") || !strcmp(mode, "a+b"))
		return O_RDWR | O_CREAT | O_APPEND | O_BINARY;

	return -1;
}

@implementation OFFile
+ (void)initialize
{
	if (self != [OFFile class])
		return;

#if defined(OF_HAVE_CHOWN) && defined(OF_HAVE_THREADS)
	if (!of_mutex_new(&mutex))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif

#ifdef __wii__
	if (!fatInitDefault())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif
}

+ (instancetype)fileWithPath: (OFString*)path
			mode: (OFString*)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}

+ (instancetype)fileWithFileDescriptor: (int)filedescriptor
{
	return [[[self alloc]
	    initWithFileDescriptor: filedescriptor] autorelease];
}

+ (OFString*)currentDirectoryPath
{
	OFString *ret;
#ifndef _WIN32
	char *buffer = getcwd(NULL, 0);
#else
	wchar_t *buffer = _wgetcwd(NULL, 0);
#endif

	@try {
#ifndef _WIN32
		ret = [OFString stringWithCString: buffer
					 encoding: OF_STRING_ENCODING_NATIVE];
#else
		ret = [OFString stringWithUTF16String: buffer];
#endif
	} @finally {
		free(buffer);
	}

	return ret;
}

+ (bool)fileExistsAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		return false;
#else
	struct _stat s;

	if (_wstat([path UTF16String], &s) == -1)
		return false;
#endif

	if (S_ISREG(s.st_mode))
		return true;

	return false;
}

+ (bool)directoryExistsAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		return false;
#else
	struct _stat s;

	if (_wstat([path UTF16String], &s) == -1)
		return false;
#endif

	if (S_ISDIR(s.st_mode))
		return true;

	return false;
}

#ifdef OF_HAVE_SYMLINK
+ (bool)symbolicLinkExistsAtPath: (OFString*)path
{
	struct stat s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (lstat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		return false;

	if (S_ISLNK(s.st_mode))
		return true;

	return false;
}
#endif

+ (void)createDirectoryAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	if (mkdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    DIR_MODE))
#else
	if (_wmkdir([path UTF16String]))
#endif
		@throw [OFCreateDirectoryFailedException
		    exceptionWithPath: path];
}

+ (void)createDirectoryAtPath: (OFString*)path
		createParents: (bool)createParents
{
	void *pool;
	OFArray *pathComponents;
	OFString *currentPath = nil, *component;
	OFEnumerator *enumerator;

	if (!createParents) {
		[OFFile createDirectoryAtPath: path];
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
		    ![OFFile directoryExistsAtPath: currentPath])
			[OFFile createDirectoryAtPath: currentPath];

		[currentPath retain];

		objc_autoreleasePoolPop(pool2);

		[currentPath autorelease];
	}

	objc_autoreleasePoolPop(pool);
}

+ (OFArray*)contentsOfDirectoryAtPath: (OFString*)path
{
	OFMutableArray *files;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	files = [OFMutableArray array];

#ifndef _WIN32
	DIR *dir;
	struct dirent *dirent;

	if ((dir = opendir([path cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE])) == NULL)
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"r"];

	@try {
		while ((dirent = readdir(dir)) != NULL) {
			void *pool = objc_autoreleasePoolPush();
			OFString *file;

			if (!strcmp(dirent->d_name, ".") ||
			    !strcmp(dirent->d_name, ".."))
				continue;

			file = [OFString
			    stringWithCString: dirent->d_name
				     encoding: OF_STRING_ENCODING_NATIVE];
			[files addObject: file];

			objc_autoreleasePoolPop(pool);
		}
	} @finally {
		closedir(dir);
	}
#else
	void *pool = objc_autoreleasePoolPush();
	HANDLE handle;
	WIN32_FIND_DATAW fd;

	path = [path stringByAppendingString: @"\\*"];

	if ((handle = FindFirstFileW([path UTF16String],
	    &fd)) == INVALID_HANDLE_VALUE)
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"r"];

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
	} @finally {
		FindClose(handle);
	}

	objc_autoreleasePoolPop(pool);
#endif

	[files makeImmutable];

	return files;
}

+ (void)changeCurrentDirectoryPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	if (chdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wchdir([path UTF16String]))
#endif
		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path];
}

+ (off_t)sizeOfFileAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
#else
	struct _stat s;

	if (_wstat([path UTF16String], &s) == -1)
#endif
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"r"];

	/* On Android, off_t is 32 bit, but st_size is long long there */
	return (off_t)s.st_size;
}

+ (OFDate*)modificationDateOfFileAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
#else
	struct _stat s;

	if (_wstat([path UTF16String], &s) == -1)
#endif
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"r"];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_mtime];
}

#ifdef OF_HAVE_CHMOD
+ (void)changePermissionsOfItemAtPath: (OFString*)path
			  permissions: (mode_t)permissions
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

# ifndef _WIN32
	if (chmod([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    permissions))
# else
	if (_wchmod([path UTF16String], permissions))
# endif
		@throw [OFChangePermissionsFailedException
		    exceptionWithPath: path
			  permissions: permissions];
}
#endif

#ifdef OF_HAVE_CHOWN
+ (void)changeOwnerOfItemAtPath: (OFString*)path
			  owner: (OFString*)owner
			  group: (OFString*)group
{
	uid_t uid = -1;
	gid_t gid = -1;

	if (path == nil || (owner == nil && group == nil))
		@throw [OFInvalidArgumentException exception];

# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE])) == NULL)
				@throw [OFChangeOwnerFailedException
				    exceptionWithPath: path
						owner: owner
						group: group];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE])) == NULL)
				@throw [OFChangeOwnerFailedException
				    exceptionWithPath: path
						owner: owner
						group: group];

			gid = group_->gr_gid;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
# endif

	if (chown([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    uid, gid))
		@throw [OFChangeOwnerFailedException exceptionWithPath: path
								 owner: owner
								 group: group];
}
#endif

+ (void)copyFileAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool;
	bool override;
	OFFile *sourceFile = nil;
	OFFile *destinationFile = nil;
	char *buffer;
	size_t pageSize;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFArray *components = [OFArray arrayWithObjects:
		    destination, [source lastPathComponent], nil];
		destination = [OFString pathWithComponents: components];
	}

	override = [self fileExistsAtPath: destination];
	pageSize = [OFSystemInfo pageSize];

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
		if (!override) {
			struct stat s;

			if (fstat(sourceFile->_fd, &s) == 0)
				[self changePermissionsOfItemAtPath: destination
							permissions: s.st_mode];
		}
#else
		(void)override;
#endif
	} @finally {
		[sourceFile close];
		[destinationFile close];
		free(buffer);
	}

	objc_autoreleasePoolPop(pool);
}

+ (void)renameItemAtPath: (OFString*)source
		  toPath: (OFString*)destination
{
	void *pool;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFArray *components = [OFArray arrayWithObjects:
		    destination, [source lastPathComponent], nil];
		destination = [OFString pathWithComponents: components];
	}

#ifndef _WIN32
	if (rename([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wrename([source UTF16String], [destination UTF16String]))
#endif
		@throw [OFRenameItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}

+ (void)removeItemAtPath: (OFString*)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
	if (remove([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wremove([path UTF16String]))
#endif
		@throw [OFRemoveItemFailedException exceptionWithPath: path];
}

#ifdef OF_HAVE_LINK
+ (void)linkItemAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFArray *components = [OFArray arrayWithObjects:
		    destination, [source lastPathComponent], nil];
		destination = [OFString pathWithComponents: components];
	}

	if (link([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]) != 0)
		@throw [OFLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_HAVE_SYMLINK
+ (void)createSymbolicLinkAtPath: (OFString*)destination
	     withDestinationPath: (OFString*)source
{
	void *pool;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFArray *components = [OFArray arrayWithObjects:
		    destination, [source lastPathComponent], nil];
		destination = [OFString pathWithComponents: components];
	}

	if (symlink([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]) != 0)
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}

+ (OFString*)destinationOfSymbolicLinkAtPath: (OFString*)path
{
	char destination[PATH_MAX];
	ssize_t length;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	length = readlink([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    destination, PATH_MAX);

	if (length < 0)
		@throw [OFOpenFileFailedException exceptionWithPath: path
							       mode: @"r"];

	return [OFString stringWithCString: destination
				  encoding: OF_STRING_ENCODING_NATIVE
				    length: length];
}
#endif

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	self = [super init];

	@try {
		int flags;

		if ((flags = parseMode([mode UTF8String])) == -1)
			@throw [OFInvalidArgumentException exception];

#ifndef _WIN32
		if ((_fd = open([path cStringWithEncoding:
		    OF_STRING_ENCODING_NATIVE], flags, DEFAULT_MODE)) == -1)
#else
		if ((_fd = _wopen([path UTF16String], flags,
		    DEFAULT_MODE)) == -1)
#endif
			@throw [OFOpenFileFailedException
			    exceptionWithPath: path
					 mode: mode];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFileDescriptor: (int)fd
{
	self = [super init];

	_fd = fd;

	return self;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_fd == -1)
		return true;

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_fd == -1 || _atEndOfStream ||
	    (ret = read(_fd, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithStream: self
						  requestedLength: length];

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (_fd == -1 || _atEndOfStream || write(_fd, buffer, length) < length)
		@throw [OFWriteFailedException exceptionWithStream: self
						   requestedLength: length];
}

- (off_t)lowlevelSeekToOffset: (off_t)offset
		       whence: (int)whence
{
	off_t ret = lseek(_fd, offset, whence);

	if (ret == -1)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence];

	return ret;
}

- (int)fileDescriptorForReading
{
	return _fd;
}

- (int)fileDescriptorForWriting
{
	return _fd;
}

- (void)close
{
	if (_fd != -1)
		close(_fd);

	_fd = -1;
}

- (void)dealloc
{
	if (_fd != -1)
		close(_fd);

	[super dealloc];
}
@end
