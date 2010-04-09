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

#import "OFFile.h"
#import "OFString.h"
#import "OFExceptions.h"

#ifdef _WIN32
# import <windows.h>
#endif

#ifndef O_BINARY
# define O_BINARY 0
#endif

#define DEFAULT_MODE S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH

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

+ (void)rename: (OFString*)from
	    to: (OFString*)to
{
#ifndef _WIN32
	if (rename([from cString], [to cString]))
#else
	if (!MoveFile([from cString], [to cString]))
#endif
		@throw [OFRenameFileFailedException newWithClass: self
							    from: from
							      to: to];
}

+ (void)delete: (OFString*)path
{
#ifndef _WIN32
	if (unlink([path cString]))
#else
	if (!DeleteFile([path cString]))
#endif
		@throw [OFDeleteFileFailedException newWithClass: self
							    path: path];
}

#ifndef _WIN32
+ (void)link: (OFString*)src
	  to: (OFString*)dest
{
	if (link([src cString], [dest cString]) != 0)
		@throw [OFLinkFailedException newWithClass: self
						    source: src
					       destination: dest];
}

+ (void)symlink: (OFString*)src
	     to: (OFString*)dest
{
	if (symlink([src cString], [dest cString]) != 0)
		@throw [OFSymlinkFailedException newWithClass: self
						       source: src
						  destination: dest];
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

- _seekToOffset: (off_t)offset
{
	if (lseek(fd, offset, SEEK_SET) == -1)
		@throw [OFSeekFailedException newWithClass: isa];

	return self;
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

- close
{
	if (fd != -1)
		close(fd);
	fd = -1;

	return self;
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
