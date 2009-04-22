/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifndef _WIN32
#include <sys/types.h>
#include <sys/stat.h>
#endif

#import "OFFile.h"
#import "OFExceptions.h"

@implementation OFFile
+ fileWithPath: (const char*)path
       andMode: (const char*)mode
{
	return [[[OFFile alloc] initWithPath: path
				   andMode: mode] autorelease];
}

+ (void)changeModeOfFile: (const char*)path
		  toMode: (mode_t)mode
{
	/*
	 * FIXME: On error, throw exception
	 * FIXME: On Win32, change write access
	 */
#ifndef _WIN32
	chmod(path, mode);
#endif
}

+ (void)changeOwnerOfFile: (const char*)path
		  toOwner: (uid_t)owner
		 andGroup: (gid_t)group
{
	/* FIXME: On error, throw exception */
#ifndef _WIN32
	chown(path, owner, group);
#endif
}

+ (void)delete: (const char*)path
{
	/* FIXME: On error, throw exception */
	unlink(path);
}

+ (void)link: (const char*)src
	  to: (const char*)dest
{
	/* FIXME: On error, throw exception */
#ifndef _WIN32
	link(src, dest);
#endif
}

+ (void)symlink: (const char*)src
	     to: (const char*)dest
{
	/* FIXME: On error, throw exception */
#ifndef _WIN32
	symlink(src, dest);
#endif
}

- initWithPath: (const char*)path
       andMode: (const char*)mode
{
	Class c;

	self = [super init];

	if ((fp = fopen(path, mode)) == NULL) {
		c = isa;
		[super free];
		@throw [OFOpenFileFailedException newWithClass: c 
						       andPath: path
						       andMode: mode];
	}

	return self;
}

- free
{
	if (fp != NULL)
		fclose(fp);

	return [super free];
}

- (BOOL)atEndOfFile
{
	if (fp == NULL)
		return YES;

	return (feof(fp) == 0 ? NO : YES);
}

- (size_t)readNItems: (size_t)nitems
	      ofSize: (size_t)size
	  intoBuffer: (char*)buf
{
	size_t ret;

	if (fp == NULL || feof(fp) ||
	    ((ret = fread(buf, size, nitems, fp)) == 0 &&
	    size != 0 && nitems != 0 && !feof(fp)))
		@throw [OFReadFailedException newWithClass: isa
						   andSize: size
						 andNItems: nitems];

	return ret;
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	return [self readNItems: size
			 ofSize: 1
		     intoBuffer: buf];
}

- (size_t)writeNItems: (size_t)nitems
	       ofSize: (size_t)size
	   fromBuffer: (const char*)buf
{
	size_t ret;

	if (fp == NULL || feof(fp) ||
	    ((ret = fwrite(buf, size, nitems, fp)) < nitems &&
	    size != 0 && nitems != 0))
		@throw [OFWriteFailedException newWithClass: isa
						    andSize: size
						  andNItems: nitems];

	return ret;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	return [self writeNItems: size
			  ofSize: 1
		      fromBuffer: buf];
}

- (size_t)writeCString: (const char*)str
{
	return [self writeNItems: strlen(str)
			  ofSize: 1
		      fromBuffer: str];
}

- close
{
	fclose(fp);
	fp = NULL;

	return self;
}
@end
