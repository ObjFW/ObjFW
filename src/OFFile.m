/*
 * Copyright (c) 2008 - 2009
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

#ifndef _WIN32
#include <sys/types.h>
#include <sys/stat.h>
#endif

#import "OFFile.h"
#import "OFExceptions.h"

#ifdef _WIN32
#import <windows.h>
#endif

OFFile *of_stdin = nil;
OFFile *of_stdout = nil;
OFFile *of_stderr = nil;

@implementation OFFile
+ (void)load
{
	if (self != [OFFile class])
		return;

	of_stdin = [[OFFileSingleton alloc] initWithFilePointer: stdin];
	of_stdout = [[OFFileSingleton alloc] initWithFilePointer: stdout];
	of_stderr = [[OFFileSingleton alloc] initWithFilePointer: stderr];
}

+ fileWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}

+ fileWithFilePointer: (FILE*)fp_
{
	return [[[self alloc] initWithFilePointer: fp_] autorelease];
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

+ (void)changeOwnerOfFile: (OFString*)path
		  toOwner: (uid_t)owner
		    group: (gid_t)group
{
#ifndef _WIN32
	if (chown([path cString], owner, group))
		@throw [OFChangeFileOwnerFailedException newWithClass: self
								 path: path
								owner: owner
								group: group];
#endif
}

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

+ (void)link: (OFString*)src
	  to: (OFString*)dest
{
#ifndef _WIN32
	if (link([src cString], [dest cString]) != 0)
		@throw [OFLinkFailedException newWithClass: self
						    source: src
					       destination: dest];
#else
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
#endif
}

+ (void)symlink: (OFString*)src
	     to: (OFString*)dest
{
#ifndef _WIN32
	if (symlink([src cString], [dest cString]) != 0)
		@throw [OFSymlinkFailedException newWithClass: self
						       source: src
						  destination: dest];
#else
	@throw [OFNotImplementedException newWithClass: self
					      selector: _cmd];
#endif
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithPath: (OFString*)path
	  mode: (OFString*)mode
{
	Class c;

	self = [super init];

	if ((fp = fopen([path cString], [mode cString])) == NULL) {
		c = isa;
		[super dealloc];
		@throw [OFOpenFileFailedException newWithClass: c
							  path: path
							  mode: mode];
	}

	close = YES;

	return self;
}

- initWithFilePointer: (FILE*)fp_
{
	self = [super init];

	fp = fp_;

	return self;
}

- (void)dealloc
{
	if (close && fp != NULL)
		fclose(fp);

	[super dealloc];
}

- (BOOL)atEndOfStreamWithoutCache
{
	if (fp == NULL)
		return YES;

	return (feof(fp) == 0 ? NO : YES);
}

- (size_t)readNBytesWithoutCache: (size_t)size
		      intoBuffer: (char*)buf
{
	size_t ret;

	if (fp == NULL || feof(fp) || ((ret = fread(buf, 1, size, fp)) == 0 &&
	    size != 0 && !feof(fp)))
		@throw [OFReadFailedException newWithClass: isa
						      size: size];

	return ret;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	size_t ret;

	if (fp == NULL || feof(fp) ||
	    ((ret = fwrite(buf, 1, size, fp)) < size && size != 0))
		@throw [OFWriteFailedException newWithClass: isa
						       size: size];

	return ret;
}

- close
{
	fclose(fp);
	fp = NULL;

	return self;
}
@end

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
