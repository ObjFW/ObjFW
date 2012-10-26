/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#ifndef _WIN32
# include <pwd.h>
# include <grp.h>
#endif

#import "OFFile.h"
#import "OFString.h"
#import "OFArray.h"
#ifdef OF_THREADS
# import "threading.h"
#endif
#import "OFDate.h"
#import "OFApplication.h"

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
#import "OFNotImplementedException.h"
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
# import <windows.h>
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

OFStream *of_stdin = nil;
OFStream *of_stdout = nil;
OFStream *of_stderr = nil;

#if defined(OF_THREADS) && !defined(_WIN32)
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

void
of_log(OFConstantString *format, ...)
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *date;
	OFString *dateString, *me, *msg;
	va_list arguments;

	date = [OFDate date];
	dateString = [date localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
	me = [[OFApplication programName] lastPathComponent];

	va_start(arguments, format);
	msg = [[[OFString alloc] initWithFormat: format
				      arguments: arguments] autorelease];
	va_end(arguments);

	[of_stderr writeFormat: @"[%@.%03d %@(%d)] %@\n", dateString,
				[date microsecond] / 1000, me, getpid(), msg];

	objc_autoreleasePoolPop(pool);
}

@interface OFFileSingleton: OFFile
@end

@implementation OFFile
#if defined(OF_THREADS) && !defined(_WIN32)
+ (void)initialize
{
	if (self != [OFFile class])
		return;

	if (!of_mutex_new(&mutex))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

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
	char *buffer = getcwd(NULL, 0);

	@try {
		ret = [OFString stringWithCString: buffer
					 encoding: OF_STRING_ENCODING_NATIVE];
	} @finally {
		free(buffer);
	}

	return ret;
}

+ (BOOL)fileExistsAtPath: (OFString*)path
{
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		return NO;

	if (S_ISREG(s.st_mode))
		return YES;

	return NO;
}

+ (BOOL)directoryExistsAtPath: (OFString*)path
{
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		return NO;

	if (S_ISDIR(s.st_mode))
		return YES;

	return NO;
}

+ (void)createDirectoryAtPath: (OFString*)path
{
#ifndef _WIN32
	if (mkdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    DIR_MODE))
#else
	if (mkdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#endif
		@throw [OFCreateDirectoryFailedException
		    exceptionWithClass: self
				  path: path];
}

+ (void)createDirectoryAtPath: (OFString*)path
		createParents: (BOOL)createParents
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

		if (![currentPath isEqual: @""] &&
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
	WIN32_FIND_DATA fd;

	path = [path stringByAppendingString: @"\\*"];

	if ((handle = FindFirstFile([path cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE], &fd)) == INVALID_HANDLE_VALUE)
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
								mode: @"r"];

	@try {
		do {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *file;

			if (!strcmp(fd.cFileName, ".") ||
			    !strcmp(fd.cFileName, ".."))
				continue;

			file = [OFString
			    stringWithCString: fd.cFileName
				     encoding: OF_STRING_ENCODING_NATIVE];
			[files addObject: file];

			objc_autoreleasePoolPop(pool2);
		} while (FindNextFile(handle, &fd));
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
	if (chdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
		@throw [OFChangeDirectoryFailedException
		    exceptionWithClass: self
				  path: path];
}

#ifndef _PSP
+ (void)changeModeOfFileAtPath: (OFString*)path
			  mode: (mode_t)mode
{
# ifndef _WIN32
	if (chmod([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE], mode))
		@throw [OFChangeFileModeFailedException
		    exceptionWithClass: self
				  path: path
				  mode: mode];
# else
	DWORD attributes = GetFileAttributes(
	    [path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]);

	if (attributes == INVALID_FILE_ATTRIBUTES)
		@throw [OFChangeFileModeFailedException
		    exceptionWithClass: self
				  path: path
				  mode: mode];

	if ((mode / 100) & 2)
		attributes &= ~FILE_ATTRIBUTE_READONLY;
	else
		attributes |= FILE_ATTRIBUTE_READONLY;

	if (!SetFileAttributes([path cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE], attributes))
		@throw [OFChangeFileModeFailedException
		    exceptionWithClass: self
				  path: path
				  mode: mode];
# endif
}
#endif

+ (off_t)sizeOfFileAtPath: (OFString*)path
{
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
								mode: @"r"];

	return s.st_size;
}

+ (OFDate*)modificationDateOfFileAtPath: (OFString*)path
{
	struct stat s;

	if (stat([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    &s) == -1)
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException exceptionWithClass: self
								path: path
								mode: @"r"];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_mtime];
}

#if !defined(_WIN32) && !defined(_PSP)
+ (void)changeOwnerOfFileAtPath: (OFString*)path
			  owner: (OFString*)owner
			  group: (OFString*)group
{
	uid_t uid = -1;
	gid_t gid = -1;

	if (owner == nil && group == nil)
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

# ifdef OF_THREADS
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
# ifdef OF_THREADS
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
	BOOL override;
	OFFile *sourceFile = nil;
	OFFile *destinationFile = nil;
	char *buffer;

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

	override = [self fileExistsAtPath: destination];

	if ((buffer = malloc(of_pagesize)) == NULL)
		@throw [OFOutOfMemoryException exceptionWithClass: self
						    requestedSize: of_pagesize];

	@try {
		sourceFile = [OFFile fileWithPath: source
					     mode: @"rb"];
		destinationFile = [OFFile fileWithPath: destination
						  mode: @"wb"];

		while (![sourceFile isAtEndOfStream]) {
			size_t length;

			length = [sourceFile readIntoBuffer: buffer
						     length: of_pagesize];
			[destinationFile writeBuffer: buffer
					      length: length];
		}

#if !defined(_WIN32) && !defined(_PSP)
		if (!override) {
			struct stat s;

			if (fstat(sourceFile->fd, &s) == 0)
				fchmod(destinationFile->fd, s.st_mode);
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
	if (!MoveFile([source cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    [destination cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
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
	if (!DeleteFile([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
#endif
		@throw [OFDeleteFileFailedException exceptionWithClass: self
								  path: path];
}

+ (void)deleteDirectoryAtPath: (OFString*)path
{
	if (rmdir([path cStringWithEncoding: OF_STRING_ENCODING_NATIVE]))
		@throw [OFDeleteDirectoryFailedException
		    exceptionWithClass: self
				  path: path];
}

#ifndef _WIN32
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

#if !defined(_WIN32) && !defined(_PSP)
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
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	self = [super init];

	@try {
		int flags;

		if ((flags = parse_mode([mode cStringWithEncoding:
		    OF_STRING_ENCODING_NATIVE])) == -1)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		if ((fd = open([path cStringWithEncoding:
		    OF_STRING_ENCODING_NATIVE], flags, DEFAULT_MODE)) == -1)
			@throw [OFOpenFileFailedException
			    exceptionWithClass: [self class]
					  path: path
					  mode: mode];

		closable = YES;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFileDescriptor: (int)fileDescriptor
{
	self = [super init];

	fd = fileDescriptor;

	return self;
}

- (BOOL)lowlevelIsAtEndOfStream
{
	if (fd == -1)
		return YES;

	return atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (fd == -1 || atEndOfStream || (ret = read(fd, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithClass: [self class]
							  stream: self
						 requestedLength: length];

	if (ret == 0)
		atEndOfStream = YES;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (fd == -1 || atEndOfStream || write(fd, buffer, length) < length)
		@throw [OFWriteFailedException exceptionWithClass: [self class]
							   stream: self
						  requestedLength: length];
}

- (void)lowlevelSeekToOffset: (off_t)offset
{
	if (lseek(fd, offset, SEEK_SET) == -1)
		@throw [OFSeekFailedException exceptionWithClass: [self class]
							  stream: self
							  offset: offset
							  whence: SEEK_SET];
}

- (off_t)lowlevelSeekForwardWithOffset: (off_t)offset
{
	off_t ret;

	if ((ret = lseek(fd, offset, SEEK_CUR)) == -1)
		@throw [OFSeekFailedException exceptionWithClass: [self class]
							  stream: self
							  offset: offset
							  whence: SEEK_CUR];

	return ret;
}

- (off_t)lowlevelSeekToOffsetRelativeToEnd: (off_t)offset
{
	off_t ret;

	if ((ret = lseek(fd, offset, SEEK_END)) == -1)
		@throw [OFSeekFailedException exceptionWithClass: [self class]
							  stream: self
							  offset: offset
							  whence: SEEK_END];

	return ret;
}

- (int)fileDescriptorForReading
{
	return fd;
}

- (int)fileDescriptorForWriting
{
	return fd;
}

- (void)close
{
	if (fd != -1)
		close(fd);

	fd = -1;
}

- (void)dealloc
{
	if (closable && fd != -1)
		close(fd);

	[super dealloc];
}
@end

@implementation OFFileSingleton
+ (void)load
{
	of_stdin = [[OFFileSingleton alloc] initWithFileDescriptor: 0];
	of_stdout = [[OFFileSingleton alloc] initWithFileDescriptor: 1];
	of_stderr = [[OFFileSingleton alloc] initWithFileDescriptor: 2];
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- autorelease
{
	return self;
}

- retain
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

- (void)dealloc
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
	[super dealloc];	/* Get rid of stupid warning */
}

- (void)lowlevelSeekToOffset: (off_t)offset
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (off_t)lowlevelSeekForwardWithOffset: (off_t)offset
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (off_t)lowlevelSeekToOffsetRelativeToEnd: (off_t)offset
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}
@end
