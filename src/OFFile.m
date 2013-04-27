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

#import "OFChangeDirectoryFailedException.h"
#import "OFChangeFileModeFailedException.h"
#import "OFChangeFileOwnerFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFDeleteDirectoryFailedException.h"
#import "OFDeleteFileFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkFailedException.h"
#import "OFLockFailedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"
#import "OFRenameFileFailedException.h"
#import "OFSeekFailedException.h"
#import "OFSymlinkFailedException.h"
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

static int parse_mode(const char *mode)
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

+ (void)createDirectoryAtPath: (OFString*)path
{
#ifndef _WIN32
	if (mkdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    DIR_MODE))
#else
	if (_wmkdir([path UTF16String]))
#endif
		@throw [OFCreateDirectoryFailedException
		    exceptionWithClass: self
				  path: path];
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

	pool = objc_autoreleasePoolPush();

	pathComponents = [path pathComponents];
	enumerator = [pathComponents objectEnumerator];
	while ((component = [enumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		if (currentPath != nil)
			currentPath = [OFString
			    stringWithPath: currentPath, component, nil];
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

+ (OFArray*)filesInDirectoryAtPath: (OFString*)path
{
	OFMutableArray *files = [OFMutableArray array];

#ifndef _WIN32
	DIR *dir;
	struct dirent *dirent;

	if ((dir = opendir([path cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE])) == NULL)
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
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
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
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

+ (void)changeToDirectoryAtPath: (OFString*)path
{
#ifndef _WIN32
	if (chdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wchdir([path UTF16String]))
#endif
		@throw [OFChangeDirectoryFailedException
		    exceptionWithClass: self
				  path: path];
}

#ifdef OF_HAVE_CHMOD
+ (void)changeModeOfFileAtPath: (OFString*)path
			  mode: (mode_t)mode
{
# ifndef _WIN32
	if (chmod([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE], mode))
# else
	if (_wchmod([path UTF16String], mode))
# endif
		@throw [OFChangeFileModeFailedException
		    exceptionWithClass: self
				  path: path
				  mode: mode];
}
#endif

+ (off_t)sizeOfFileAtPath: (OFString*)path
{
#ifndef _WIN32
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
#else
	struct _stat s;

	if (_wstat([path UTF16String], &s) == -1)
#endif
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
								mode: @"r"];

	return s.st_size;
}

+ (OFDate*)modificationDateOfFileAtPath: (OFString*)path
{
#ifndef _WIN32
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
#else
	struct _stat s;

	if (_wstat([path UTF16String], &s) == -1)
#endif
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
								mode: @"r"];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_mtime];
}

#ifdef OF_HAVE_CHOWN
+ (void)changeOwnerOfFileAtPath: (OFString*)path
			  owner: (OFString*)owner
			  group: (OFString*)group
{
	uid_t uid = -1;
	gid_t gid = -1;

	if (owner == nil && group == nil)
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exceptionWithClass: self];

	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE])) == NULL)
				@throw [OFChangeFileOwnerFailedException
				    exceptionWithClass: self
						  path: path
						 owner: owner
						 group: group];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE])) == NULL)
				@throw [OFChangeFileOwnerFailedException
				    exceptionWithClass: self
						  path: path
						 owner: owner
						 group: group];

			gid = group_->gr_gid;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException
			    exceptionWithClass: self];
	}
# endif

	if (chown([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    uid, gid))
		@throw [OFChangeFileOwnerFailedException
		    exceptionWithClass: self
				  path: path
				 owner: owner
				 group: group];
}
#endif

+ (void)copyFileAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool = objc_autoreleasePoolPush();
	bool override;
	OFFile *sourceFile = nil;
	OFFile *destinationFile = nil;
	char *buffer;
	size_t pageSize;

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

	override = [self fileExistsAtPath: destination];
	pageSize = [OFSystemInfo pageSize];

	if ((buffer = malloc(pageSize)) == NULL)
		@throw [OFOutOfMemoryException exceptionWithClass: self
						    requestedSize: pageSize];

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
				fchmod(destinationFile->_fd, s.st_mode);
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

+ (void)renameFileAtPath: (OFString*)source
		  toPath: (OFString*)destination
{
	void *pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

#ifndef _WIN32
	if (rename([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wrename([source UTF16String], [destination UTF16String]))
#endif
		@throw [OFRenameFileFailedException
		    exceptionWithClass: self
			    sourcePath: source
		       destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}

+ (void)deleteFileAtPath: (OFString*)path
{
#ifndef _WIN32
	if (unlink([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wunlink([path UTF16String]))
#endif
		@throw [OFDeleteFileFailedException exceptionWithClass: self
								  path: path];
}

+ (void)deleteDirectoryAtPath: (OFString*)path
{
#ifndef _WIN32
	if (rmdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#else
	if (_wrmdir([path UTF16String]))
#endif
		@throw [OFDeleteDirectoryFailedException
		    exceptionWithClass: self
				  path: path];
}

#ifdef OF_HAVE_LINK
+ (void)linkFileAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	void *pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

	if (link([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]) != 0)
		@throw [OFLinkFailedException exceptionWithClass: self
						      sourcePath: source
						 destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_HAVE_SYMLINK
+ (void)symlinkFileAtPath: (OFString*)source
		   toPath: (OFString*)destination
{
	void *pool = objc_autoreleasePoolPush();

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

	if (symlink([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]) != 0)
		@throw [OFSymlinkFailedException
		    exceptionWithClass: self
			    sourcePath: source
		       destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}
#endif

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	self = [super init];

	@try {
		int flags;

		if ((flags = parse_mode([mode UTF8String])) == -1)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

#ifndef _WIN32
		if ((_fd = open([path cStringWithEncoding:
		    OF_STRING_ENCODING_NATIVE], flags, DEFAULT_MODE)) == -1)
#else
		if ((_fd = _wopen([path UTF16String], flags,
		    DEFAULT_MODE)) == -1)
#endif
			@throw [OFOpenFileFailedException
			    exceptionWithClass: [self class]
					  path: path
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
		@throw [OFReadFailedException exceptionWithClass: [self class]
							  stream: self
						 requestedLength: length];

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (_fd == -1 || _atEndOfStream || write(_fd, buffer, length) < length)
		@throw [OFWriteFailedException exceptionWithClass: [self class]
							   stream: self
						  requestedLength: length];
}

- (void)lowlevelSeekToOffset: (off_t)offset
		      whence: (int)whence
{
	if (lseek(_fd, offset, whence) == -1)
		@throw [OFSeekFailedException exceptionWithClass: [self class]
							  stream: self
							  offset: offset
							  whence: whence];
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
