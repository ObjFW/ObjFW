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

#include <stdio.h>
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
#import "OFExceptions.h"
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

OFFile *of_stdin = nil;
OFFile *of_stdout = nil;
OFFile *of_stderr = nil;

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
of_log(OFConstantString *fmt, ...)
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFDate *date;
	OFString *date_str, *me, *msg;
	va_list args;

	date = [OFDate date];
	date_str = [date localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
	me = [OFFile lastComponentOfPath: [OFApplication programName]];

	va_start(args, fmt);
	msg = [[[OFString alloc] initWithFormat: fmt
				      arguments: args] autorelease];
	va_end(args);

	[of_stderr writeFormat: @"[%@.%03d %@(%d)] %@\n", date_str,
				[date microsecond] / 1000, me, getpid(), msg];

	[pool release];
}

@interface OFFileSingleton: OFFile
@end

@implementation OFFile
+ (void)load
{
	if (self != [OFFile class])
		return;

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

+ fileWithFileDescriptor: (int)fd_
{
	return [[[self alloc] initWithFileDescriptor: fd_] autorelease];
}

+ (OFArray*)componentsOfPath: (OFString*)path
{
	OFMutableArray *ret;
	OFAutoreleasePool *pool;
	const char *path_c = [path cString];
	size_t path_len = [path cStringLength];
	size_t i, last = 0;

	ret = [OFMutableArray array];

	if (path_len == 0)
		return ret;

	pool = [[OFAutoreleasePool alloc] init];

#ifndef _WIN32
	if (path_c[path_len - 1] == OF_PATH_DELIM)
#else
	if (path_c[path_len - 1] == '/' || path_c[path_len - 1] == '\\')
#endif
		path_len--;

	for (i = 0; i < path_len; i++) {
#ifndef _WIN32
		if (path_c[i] == OF_PATH_DELIM) {
#else
		if (path_c[i] == '/' || path_c[i] == '\\') {
#endif
			[ret addObject:
			    [OFString stringWithCString: path_c + last
						 length: i - last]];
			last = i + 1;
		}
	}

	[ret addObject: [OFString stringWithCString: path_c + last
					     length: i - last]];

	[pool release];

	return ret;
}

+ (OFString*)lastComponentOfPath: (OFString*)path
{
	const char *path_c = [path cString];
	size_t path_len = [path cStringLength];
	ssize_t i;

	if (path_len == 0)
		return @"";

#ifndef _WIN32
	if (path_c[path_len - 1] == OF_PATH_DELIM)
#else
	if (path_c[path_len - 1] == '/' || path_c[path_len - 1] == '\\')
#endif
		path_len--;

	for (i = path_len - 1; i >= 0; i--) {
#ifndef _WIN32
		if (path_c[i] == OF_PATH_DELIM) {
#else
		if (path_c[i] == '/' || path_c[i] == '\\') {
#endif
			i++;
			break;
		}
	}

	/*
	 * Only one component, but the trailing delimiter might have been
	 * removed, so return a new string anyway.
	 */
	if (i < 0)
		i = 0;

	return [OFString stringWithCString: path_c + i
				    length: path_len - i];
}

+ (OFString*)directoryNameOfPath: (OFString*)path
{
	const char *path_c = [path cString];
	size_t path_len = [path cStringLength];
	size_t i;

	if (path_len == 0)
		return @"";

#ifndef _WIN32
	if (path_c[path_len - 1] == OF_PATH_DELIM)
#else
	if (path_c[path_len - 1] == '/' || path_c[path_len - 1] == '\\')
#endif
		path_len--;

	if (path_len == 0)
		return [OFString stringWithCString: path_c
					    length: 1];

	for (i = path_len - 1; i >= 1; i--)
#ifndef _WIN32
		if (path_c[i] == OF_PATH_DELIM)
#else
		if (path_c[i] == '/' || path_c[i] == '\\')
#endif
			return [OFString stringWithCString: path_c
						    length: i];

#ifndef _WIN32
	if (path_c[0] == OF_PATH_DELIM)
#else
	if (path_c[i] == '/' || path_c[i] == '\\')
#endif
		return [OFString stringWithCString: path_c
					    length: 1];

	return @".";
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

	path = [path stringByAppendingString: @"\\*"];

	if ((handle = FindFirstFile([path cString], &fd)) ==
	    INVALID_HANDLE_VALUE)
		@throw [OFOpenFileFailedException newWithClass: self
							  path: path
							  mode: @"r"];

	@try {
		pool = [[OFAutoreleasePool alloc] init];

		do {
			OFString *file;

			if (!strcmp(fd.cFileName, ".") ||
			    !strcmp(fd.cFileName, ".."))
				continue;

			file = [OFString stringWithCString: fd.cFileName];
			[files addObject: file];

			[pool releaseObjects];
		} while (FindNextFile(handle, &fd));

		[pool release];
	} @finally {
		FindClose(handle);
	}
#endif

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
	DWORD attrs = GetFileAttributes([path cString]);

	if (attrs == INVALID_FILE_ATTRIBUTES)
		@throw [OFChangeFileModeFailedException newWithClass: self
								path: path
								mode: mode];

	if ((mode / 100) & 2)
		attrs &= ~FILE_ATTRIBUTE_READONLY;
	else
		attrs |= FILE_ATTRIBUTE_READONLY;

	if (!SetFileAttributes([path cString], attrs))
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
			struct passwd *pw;

			if ((pw = getpwnam([owner cString])) == NULL)
				@throw [OFChangeFileOwnerFailedException
				    newWithClass: self
					    path: path
					   owner: owner
					   group: group];

			uid = pw->pw_uid;
		}

		if (group != nil) {
			struct group *gr;

			if ((gr = getgrnam([group cString])) == NULL)
				@throw [OFChangeFileOwnerFailedException
				    newWithClass: self
					    path: path
					   owner: owner
					   group: group];

			gid = gr->gr_gid;
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

+ (void)copyFileAtPath: (OFString*)from
		toPath: (OFString*)to
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	BOOL override;
	OFFile *src;
	OFFile *dest;
	char buf[4096];

	if ([self directoryExistsAtPath: to]) {
		OFString *filename = [self lastComponentOfPath: from];
		to = [OFString stringWithPath: to, filename, nil];
	}

	override = [self fileExistsAtPath: to];

	src = nil;
	dest = nil;

	@try {
		src = [OFFile fileWithPath: from
				      mode: @"rb"];
		dest = [OFFile fileWithPath: to
				       mode: @"wb"];

		while (![src isAtEndOfStream]) {
			size_t len = [src readNBytes: 4096
					  intoBuffer: buf];
			[dest writeNBytes: len
			       fromBuffer: buf];
		}

#if !defined(_WIN32) && !defined(_PSP)
		if (!override) {
			struct stat s;

			if (fstat(src->fd, &s) == 0)
				fchmod(dest->fd, s.st_mode);
		}
#endif
	} @finally {
		[src close];
		[dest close];
	}

	[pool release];
}

+ (void)renameFileAtPath: (OFString*)from
		  toPath: (OFString*)to
{
	if ([self directoryExistsAtPath: to]) {
		OFString *filename = [self lastComponentOfPath: from];
		to = [OFString stringWithPath: to, filename, nil];
	}

#ifndef _WIN32
	if (rename([from cString], [to cString]))
#else
	if (!MoveFile([from cString], [to cString]))
#endif
		@throw [OFRenameFileFailedException newWithClass: self
						      sourcePath: from
						 destinationPath: to];
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
+ (void)linkFileAtPath: (OFString*)src
		toPath: (OFString*)dest
{
	if ([self directoryExistsAtPath: dest]) {
		OFString *filename = [self lastComponentOfPath: src];
		dest = [OFString stringWithPath: dest, filename, nil];
	}

	if (link([src cString], [dest cString]) != 0)
		@throw [OFLinkFailedException newWithClass: self
						sourcePath: src
					   destinationPath: dest];
}
#endif

#if !defined(_WIN32) && !defined(_PSP)
+ (void)symlinkFileAtPath: (OFString*)src
		   toPath: (OFString*)dest
{
	if ([self directoryExistsAtPath: dest]) {
		OFString *filename = [self lastComponentOfPath: src];
		dest = [OFString stringWithPath: dest, filename, nil];
	}

	if (symlink([src cString], [dest cString]) != 0)
		@throw [OFSymlinkFailedException newWithClass: self
						   sourcePath: src
					      destinationPath: dest];
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

		if ((fd = open([path cString], flags, DEFAULT_MODE)) == -1)
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

- initWithFileDescriptor: (int)fd_
{
	self = [super init];

	fd = fd_;

	return self;
}

- (BOOL)_isAtEndOfStream
{
	if (fd == -1)
		return YES;

	return eos;
}

- (size_t)_readNBytes: (size_t)size
	   intoBuffer: (char*)buf
{
	size_t ret;

	if (fd == -1 || eos)
		@throw [OFReadFailedException newWithClass: isa
					     requestedSize: size];
	if ((ret = read(fd, buf, size)) == 0)
		eos = YES;

	return ret;
}

- (size_t)_writeNBytes: (size_t)size
	    fromBuffer: (const char*)buf
{
	size_t ret;

	if (fd == -1 || eos || (ret = write(fd, buf, size)) < size)
		@throw [OFWriteFailedException newWithClass: isa
					      requestedSize: size];

	return ret;
}

- (void)_seekToOffset: (off_t)offset
{
	if (lseek(fd, offset, SEEK_SET) == -1)
		@throw [OFSeekFailedException newWithClass: isa];
}

- (size_t)_seekForwardWithOffset: (off_t)offset
{
	off_t ret;

	if ((ret = lseek(fd, offset, SEEK_CUR)) == -1)
		@throw [OFSeekFailedException newWithClass: isa];

	return ret;
}

- (size_t)_seekToOffsetRelativeToEnd: (off_t)offset
{
	off_t ret;

	if ((ret = lseek(fd, offset, SEEK_END)) == -1)
		@throw [OFSeekFailedException newWithClass: isa];

	return ret;
}

- (int)fileDescriptor
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

- (size_t)retainCount
{
	return SIZE_MAX;
}

- (void)dealloc
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of stupid warning */
}
@end
