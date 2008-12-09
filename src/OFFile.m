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

#import <sys/types.h>
#import <sys/stat.h>

#import "OFFile.h"
#import "OFExceptions.h"

@implementation OFFile
+ newWithPath: (const char*)path
      andMode: (const char*)mode
{
	return [[OFFile alloc] initWithPath: path
				    andMode: mode];
}

+ (BOOL)changeModeOfFile: (const char*)path
		 toMode: (mode_t)mode
{
	// FIXME: On error, throw exception
	return (chmod(path, mode) == 0 ? YES : NO);
}

+ (BOOL)changeOwnerOfFile: (const char*)path
		 toOwner: (uid_t)owner
		andGroup: (gid_t)group
{
	// FIXME: On error, throw exception
	return (chown(path, owner, group) == 0 ? YES : NO);
}

+ (BOOL)delete: (const char*)path
{
	// FIXME: On error, throw exception
	return (unlink(path) == 0 ? YES : NO);
}

+ (BOOL)link: (const char*)src
	 to: (const char*)dest
{
	// FIXME: On error, throw exception
	return (link(src, dest) == 0 ? YES : NO);
}

+ (BOOL)symlink: (const char*)src
	    to: (const char*)dest
{
	// FIXME: On error, throw exception
	return (symlink(src, dest) == 0 ? YES : NO);
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

- close
{
	if (fclose(fp)) {
		/* FIXME: Throw exception */
		return nil;
	}

	return self;
}
@end
