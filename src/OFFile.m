/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdio.h>
#import <string.h>
#import <unistd.h>

#ifndef _WIN32
#import <sys/types.h>
#import <sys/stat.h>
#endif

#import "OFFile.h"
#import "OFExceptions.h"

@implementation OFFile
+ newWithPath: (const char*)path
      andMode: (const char*)mode
{
	return [[self alloc] initWithPath: path
				    andMode: mode];
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
	if ((self = [super init])) {
		if ((fp = fopen(path, mode)) == NULL)
			@throw [OFOpenFileFailedException newWithObject: self
								andPath: path
								andMode: mode];
	}
	return self;
}

- free
{
	fclose(fp);

	return [super free];
}

- (BOOL)atEndOfFile
{
	return (feof(fp) == 0 ? NO : YES);
}

- (size_t)readNItems: (size_t)nitems
	      ofSize: (size_t)size
	  intoBuffer: (uint8_t*)buf
{
	size_t ret;

	if ((ret = fread(buf, size, nitems, fp)) == 0 && !feof(fp))
		@throw [OFReadFailedException newWithObject: self
						    andSize: size
						  andNItems: nitems];

	return ret;
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (uint8_t*)buf
{
	return [self readNItems: size
			 ofSize: 1
		     intoBuffer: buf];
}

- (uint8_t*)readNItems: (size_t)nitems
		ofSize: (size_t)size
{
	uint8_t	*ret;

	ret = [self getMemForNItems: nitems
			     ofSize: size];

	@try {
		[self readNItems: nitems
			  ofSize: size
		      intoBuffer: ret];
	} @catch (id exception) {
		[self freeMem: ret];
		@throw exception;
	}

	return ret;
}

- (uint8_t*)readNBytes: (size_t)size
{
	return [self readNItems: size
			 ofSize: 1];
}

- (size_t)writeNItems: (size_t)nitems
	       ofSize: (size_t)size
	   fromBuffer: (const uint8_t*)buf
{
	size_t ret;

	if ((ret = fwrite(buf, size, nitems, fp)) == 0 &&
	    size != 0 && nitems != 0)
		@throw [OFWriteFailedException newWithObject: self
						     andSize: size
						   andNItems: nitems];
	
	return ret;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const uint8_t*)buf
{
	return [self writeNItems: size
			  ofSize: 1
		      fromBuffer: buf];
}

- (size_t)writeCString: (const char*)str
{
	return [self writeNItems: strlen(str)
			  ofSize: 1
		      fromBuffer: (const uint8_t*)str];
}
@end
