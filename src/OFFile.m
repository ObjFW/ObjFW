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
#import <stdint.h>
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

+ (int)changeModeOfFile: (const char*)path
		 toMode: (mode_t)mode
{
	// FIXME: On error, throw exception
	return chmod(path, mode);
}

+ (int)changeOwnerOfFile: (const char*)path
		 toOwner: (uid_t)owner
		andGroup: (gid_t)group
{
	// FIXME: On error, throw exception
	return chown(path, owner, group);
}

+ (int)delete: (const char*)path
{
	// FIXME: On error, throw exception
	return unlink(path);
}

+ (int)link: (const char*)src
	 to: (const char*)dest
{
	// FIXME: On error, throw exception
	return link(src, dest);
}

+ (int)symlink: (const char*)src
	    to: (const char*)dest
{
	// FIXME: On error, throw exception
	return symlink(src, dest);
}

- initWithPath: (const char*)path
       andMode: (const char*)mode
{
	if ((self = [super init])) {
		if ((fp = fopen(path, mode)) == NULL) {
			[[OFOpenFileFailedException newWithObject: self
							  andPath: path
							  andMode: mode] raise];
			[self free];
			return nil;
		}
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

- (size_t)readIntoBuffer: (uint8_t*)buf
		withSize: (size_t)size
	       andNItems: (size_t)nitems
{
	size_t ret;

	if ((ret = fread(buf, size, nitems, fp)) == 0 && !feof(fp))
		[[OFReadFailedException newWithObject: self
					      andSize: size
					    andNItems: nitems] raise];

	return ret;
}

- (uint8_t*)readWithSize: (size_t)size
	       andNItems: (size_t)nitems
{
	uint64_t memsize;
	uint8_t	 *ret;
       
	if (size >= 0xFFFFFFFF || nitems >= 0xFFFFFFFF ||
	    (memsize = (uint64_t)nitems * size) > 0xFFFFFFFF) {
		[[OFOverflowException newWithObject: self] raise];
		return NULL;
	}
	
	ret = [self getMemWithSize: (size_t)memsize];

	@try {
		[self readIntoBuffer: ret
			    withSize: size
			   andNItems: nitems];
	} @catch (OFReadFailedException *e) {
		[self freeMem: ret];
		@throw e;
		return NULL;
	}

	return ret;
}

- (size_t)writeBuffer: (uint8_t*)buf
	     withSize: (size_t)size
	    andNItems: (size_t)nitems
{
	size_t ret;

	if ((ret = fwrite(buf, size, nitems, fp)) == 0 &&
	    size != 0 && nitems != 0)
		[[OFWriteFailedException newWithObject: self
					       andSize: size
					     andNItems: nitems] raise];
	
	return ret;
}
@end
