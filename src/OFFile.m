/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
# import "OFThread.h"
#endif
#import "OFDate.h"
#import "OFApplication.h"
#import "OFAutoreleasePool.h"

#import "OFChangeDirectoryFailedException.h"
#import "OFChangeFileModeFailedException.h"
#import "OFChangeFileOwnerFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFDeleteDirectoryFailedException.h"
#import "OFDeleteFileFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOpenFileFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"
#import "OFRenameFileFailedException.h"
#import "OFSeekFailedException.h"
#import "OFSymlinkFailedException.h"
#import "OFWriteFailedException.h"

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
static OFMutex *mutex;
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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
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

	[pool release];
}

@interface OFFileSingleton: OFFile
@end

@implementation OFFile
+ (void)load
{
	of_stdin = [[OFFileSingleton alloc] initWithFileDescriptor: 0];
	of_stdout = [[OFFileSingleton alloc] initWithFileDescriptor: 1];
	of_stderr = [[OFFileSingleton alloc] initWithFileDescriptor: 2];
}

#if defined(OF_THREADS) && !defined(_WIN32)
+ (void)initialize
{
	if (self == [OFFile class])
		mutex = [[OFMutex alloc] init];
}
#endif

+ fileWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}

+ fileWithFileDescriptor: (int)filedescriptor
{
	return [[[self alloc]
	    initWithFileDescriptor: filedescriptor] autorelease];
}

+ (OFString*)currentDirectoryPath
{
	OFString *ret;
	char *buffer = getcwd(NULL, 0);

	@try {
		ret = [OFString stringWithCString: buffer];
	} @finally {
		free(buffer);
	}

	return ret;
}

+ (BOOL)fileExistsAtPath: (OFString*)path
{
	struct stat s;

	if (stat([path cString], &s) == -1)
		return NO;

	if (S_ISREG(s.st_mode))
		return YES;

	return NO;
}

+ (BOOL)directoryExistsAtPath: (OFString*)path
{
	struct stat s;

	if (stat([path cString], &s) == -1)
		return NO;

	if (S_ISDIR(s.st_mode))
		return YES;

	return NO;
}

+ (void)createDirectoryAtPath: (OFString*)path
{
#ifndef _WIN32
	if (mkdir([path cString], DIR_MODE))
#else
	if (mkdir([path cString]))
#endif
		@throw [OFCreateDirectoryFailedException newWithClass: self
								 path: path];
}

+ (OFArray*)filesInDirectoryAtPath: (OFString*)path
{
	OFAutoreleasePool *pool;
	OFMutableArray *files = [OFMutableArray array];

#ifndef _WIN32
	DIR *dir;
	struct dirent *dirent;

	if ((dir = opendir([path cString])) == NULL)
		@throw [OFOpenFileFailedException newWithClass: self
							  path: path
							  mode: @"r"];

	@try {
		pool = [[OFAutoreleasePool alloc] init];

		while ((dirent = readdir(dir)) != NULL) {
			OFString *file;

			if (!strcmp(dirent->d_name, ".") ||
			    !strcmp(dirent->d_name, ".."))
				continue;

			file = [OFString stringWithCString: dirent->d_name];
			[files addObject: file];

			[pool releaseObjects];
		}

		[pool release];
	} @finally {
		closedir(dir);
	}
#else
	HANDLE handle;
	WIN32_FIND_DATA fd;

	pool = [[OFAutoreleasePool alloc] init];
	path = [path stringByAppendingString: @"\\*"];

	if ((handle = FindFirstFile([path cString], &fd)) ==
	    INVALID_HANDLE_VALUE)
		@throw [OFOpenFileFailedException newWithClass: self
							  path: path
							  mode: @"r"];

	@try {
		OFAutoreleasePool *pool2 = [[OFAutoreleasePool alloc] init];

		do {
			OFString *file;

			if (!strcmp(fd.cFileName, ".") ||
			    !strcmp(fd.cFileName, ".."))
				continue;

			file = [OFString stringWithCString: fd.cFileName];
			[files addObject: file];

			[pool2 releaseObjects];
		} while (FindNextFile(handle, &fd));

		[pool2 release];
	} @finally {
		FindClose(handle);
	}

	[pool release];
#endif

	[files makeImmutable];

	return files;
}

+ (void)changeToDirectory: (OFString*)path
{
	if (chdir([path cString]))
		@throw [OFChangeDirectoryFailedException newWithClass: self
								 path: path];
}

#ifndef _PSP
+ (void)changeModeOfFile: (OFString*)path
		  toMode: (mode_t)mode
{
# ifndef _WIN32
	if (chmod([path cString], mode))
		@throw [OFChangeFileModeFailedException newWithClass: self
								path: path
								mode: mode];
# else
	DWORD attributes = GetFileAttributes([path cString]);

	if (attributes == INVALID_FILE_ATTRIBUTES)
		@throw [OFChangeFileModeFailedException newWithClass: self
								path: path
								mode: mode];

	if ((mode / 100) & 2)
		attributes &= ~FILE_ATTRIBUTE_READONLY;
	else
		attributes |= FILE_ATTRIBUTE_READONLY;

	if (!SetFileAttributes([path cString], attributes))
		@throw [OFChangeFileModeFailedException newWithClass: self
								path: path
								mode: mode];
# endif
}
#endif

+ (OFDate*)modificationDateOfFile: (OFString*)path
{
	struct stat s;

	if (stat([path cString], &s) == -1)
		/* FIXME: Maybe use another exception? */
		@throw [OFOpenFileFailedException newWithClass: self
							  path: path
							  mode: @"r"];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_mtime];
}

#if !defined(_WIN32) && !defined(_PSP)
+ (void)changeOwnerOfFile: (OFString*)path
		  toOwner: (OFString*)owner
		    group: (OFString*)group
{
	uid_t uid = -1;
	gid_t gid = -1;

	if (owner == nil && group == nil)
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner cString])) == NULL)
				@throw [OFChangeFileOwnerFailedException
				    newWithClass: self
					    path: path
					   owner: owner
					   group: group];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group cString])) == NULL)
				@throw [OFChangeFileOwnerFailedException
				    newWithClass: self
					    path: path
					   owner: owner
					   group: group];

			gid = group_->gr_gid;
		}
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif

	if (chown([path cString], uid, gid))
		@throw [OFChangeFileOwnerFailedException newWithClass: self
								 path: path
								owner: owner
								group: group];
}
#endif

+ (void)copyFileAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
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
		@throw [OFOutOfMemoryException newWithClass: self
					      requestedSize: of_pagesize];

	@try {
		sourceFile = [OFFile fileWithPath: source
					     mode: @"rb"];
		destinationFile = [OFFile fileWithPath: destination
						  mode: @"wb"];

		while (![sourceFile isAtEndOfStream]) {
			size_t len = [sourceFile readNBytes: of_pagesize
						 intoBuffer: buffer];
			[destinationFile writeNBytes: len
					  fromBuffer: buffer];
		}

#if !defined(_WIN32) && !defined(_PSP)
		if (!override) {
			struct stat s;

			if (fstat(sourceFile->fileDescriptor, &s) == 0)
				fchmod(destinationFile->fileDescriptor,
				    s.st_mode);
		}
#endif
	} @finally {
		[sourceFile close];
		[destinationFile close];
		free(buffer);
	}

	[pool release];
}

+ (void)renameFileAtPath: (OFString*)source
		  toPath: (OFString*)destination
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

#ifndef _WIN32
	if (rename([source cString], [destination cString]))
#else
	if (!MoveFile([source cString], [destination cString]))
#endif
		@throw [OFRenameFileFailedException newWithClass: self
						      sourcePath: source
						 destinationPath: destination];

	[pool release];
}

+ (void)deleteFileAtPath: (OFString*)path
{
#ifndef _WIN32
	if (unlink([path cString]))
#else
	if (!DeleteFile([path cString]))
#endif
		@throw [OFDeleteFileFailedException newWithClass: self
							    path: path];
}

+ (void)deleteDirectoryAtPath: (OFString*)path
{
	if (rmdir([path cString]))
		@throw [OFDeleteDirectoryFailedException newWithClass: self
								 path: path];
}

#ifndef _WIN32
+ (void)linkFileAtPath: (OFString*)source
		toPath: (OFString*)destination
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

	if (link([source cString], [destination cString]) != 0)
		@throw [OFLinkFailedException newWithClass: self
						sourcePath: source
					   destinationPath: destination];

	[pool release];
}
#endif

#if !defined(_WIN32) && !defined(_PSP)
+ (void)symlinkFileAtPath: (OFString*)source
		   toPath: (OFString*)destination
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	if ([self directoryExistsAtPath: destination]) {
		OFString *filename = [source lastPathComponent];
		destination = [OFString stringWithPath: destination, filename,
							nil];
	}

	if (symlink([source cString], [destination cString]) != 0)
		@throw [OFSymlinkFailedException newWithClass: self
						   sourcePath: source
					      destinationPath: destination];

	[pool release];
}
#endif

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	self = [super init];

	@try {
		int flags;

		if ((flags = parse_mode([mode cString])) == -1)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		if ((fileDescriptor = open([path cString], flags,
		    DEFAULT_MODE)) == -1)
			@throw [OFOpenFileFailedException newWithClass: isa
								  path: path
								  mode: mode];

		closable = YES;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFileDescriptor: (int)fileDescriptor_
{
	self = [super init];

	fileDescriptor = fileDescriptor_;

	return self;
}

- (BOOL)_isAtEndOfStream
{
	if (fileDescriptor == -1)
		return YES;

	return isAtEndOfStream;
}

- (size_t)_readNBytes: (size_t)length
	   intoBuffer: (void*)buffer
{
	size_t ret;

	if (fileDescriptor == -1 || isAtEndOfStream)
		@throw [OFReadFailedException newWithClass: isa
						    stream: self
					   requestedLength: length];

	if ((ret = read(fileDescriptor, buffer, length)) == 0)
		isAtEndOfStream = YES;

	return ret;
}

- (void)_writeNBytes: (size_t)length
	  fromBuffer: (const void*)buffer
{
	if (fileDescriptor == -1 || isAtEndOfStream ||
	    write(fileDescriptor, buffer, length) < length)
		@throw [OFWriteFailedException newWithClass: isa
						     stream: self
					    requestedLength: length];
}

- (void)_seekToOffset: (off_t)offset
{
	if (lseek(fileDescriptor, offset, SEEK_SET) == -1)
		@throw [OFSeekFailedException newWithClass: isa
						    stream: self
						    offset: offset
						    whence: SEEK_SET];
}

- (off_t)_seekForwardWithOffset: (off_t)offset
{
	off_t ret;

	if ((ret = lseek(fileDescriptor, offset, SEEK_CUR)) == -1)
		@throw [OFSeekFailedException newWithClass: isa
						    stream: self
						    offset: offset
						    whence: SEEK_CUR];

	return ret;
}

- (off_t)_seekToOffsetRelativeToEnd: (off_t)offset
{
	off_t ret;

	if ((ret = lseek(fileDescriptor, offset, SEEK_END)) == -1)
		@throw [OFSeekFailedException newWithClass: isa
						    stream: self
						    offset: offset
						    whence: SEEK_END];

	return ret;
}

- (int)fileDescriptor
{
	return fileDescriptor;
}

- (void)close
{
	if (fileDescriptor != -1)
		close(fileDescriptor);

	fileDescriptor = -1;
}

- (void)dealloc
{
	if (closable && fileDescriptor != -1)
		close(fileDescriptor);

	[super dealloc];
}
@end

@implementation OFFileSingleton
- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
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
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of stupid warning */
}

- (void)_seekToOffset: (off_t)offset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (off_t)_seekForwardWithOffset: (off_t)offset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (off_t)_seekToOffsetRelativeToEnd: (off_t)offset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
