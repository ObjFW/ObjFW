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

#include "config.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>

#import "OFFile.h"
#import "OFString.h"
#import "OFArray.h"
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

/// \cond internal
@interface OFFileSingleton: OFFile
@end
/// \endcond

@implementation OFFile
+ (void)load
{
	if (self != [OFFile class])
		return;

	of_stdin = [[OFFileSingleton alloc] initWithFileDescriptor: 0];
	of_stdout = [[OFFileSingleton alloc] initWithFileDescriptor: 1];
	of_stderr = [[OFFileSingleton alloc] initWithFileDescriptor: 2];
}

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

+ (void)changeModeOfFile: (OFString*)path
		  toMode: (mode_t)mode
{
#ifndef _WIN32
	if (chmod([path cString], mode))
		@throw [OFChangeFileModeFailedException newWithClass: self
								path: path
								mode: mode];
#else
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
#endif
}

#ifndef _WIN32
+ (void)changeOwnerOfFile: (OFString*)path
		  toOwner: (uid_t)owner
		    group: (gid_t)group
{
	if (chown([path cString], owner, group))
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

		while (![src atEndOfStream]) {
			size_t len = [src readNBytes: 4096
					  intoBuffer: buf];
			[dest writeNBytes: len
			       fromBuffer: buf];
		}

#ifndef _WIN32
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
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	Class c;
	int flags;

	self = [super init];

	if ((flags = parse_mode([mode cString])) == -1) {
		c = isa;
		[super dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	if ((fd = open([path cString], flags, DEFAULT_MODE)) == -1) {
		c = isa;
		[super dealloc];
		@throw [OFOpenFileFailedException newWithClass: c
							  path: path
							  mode: mode];
	}

	closable = YES;

	return self;
}

- initWithFileDescriptor: (int)fd_
{
	self = [super init];

	fd = fd_;

	return self;
}

- (BOOL)_atEndOfStream
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
						      size: size];
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
						       size: size];

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

/// \cond internal
@implementation OFFileSingleton
- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	@throw [OFNotImplementedException newWithClass: isa
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
/// \endcond
