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

#import <stdio.h>

#import "OFFile.h"
#import "OFExceptions.h"

@implementation OFFile
+ newWithPath: (const char*)path
      andMode: (const char*)mode
{
	return [[OFFile alloc] initWithPath: path
				    andMode: mode];
}

- initWithPath: (const char*)path
       andMode: (const char*)mode
{
	if ((self = [super init])) {
		if ((fp = fopen(path, mode)) == NULL) {
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

- (BOOL)isEndOfFile
{
	return feof(fp);
}

- (size_t)readIntoBuffer: (char*)buf
		withSize: (size_t)size
	       andNItems: (size_t)nitems
{
	size_t ret;

	if ((ret = fread(buf, size, nitems, fp)) == 0 && ![self isEndOfFile])
		[OFReadFailedException newWithObject: self
					     andSize: size
					   andNItems: nitems];

	return ret;
}

- (char*)readWithSize: (size_t)size
	    andNItems: (size_t)nitems
{
	uint64_t memsize;
	char *ret;
       
	if (size >= 0xFFFFFFFF || nitems >= 0xFFFFFFFF ||
	    (memsize = (uint64_t)nitems * size) > 0xFFFFFFFF) {
		[OFOverflowException newWithObject: self];
		return NULL;
	}
	
	ret = [self getMem: (size_t)memsize];

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

- (size_t)writeBuffer: (char*)buf
	     withSize: (size_t)size
	    andNItems: (size_t)nitems
{
	size_t ret;

	if ((ret = fwrite(buf, size, nitems, fp)) == 0 &&
	    size != 0 && nitems != 0)
		[OFWriteFailedException newWithObject: self
					      andSize: size
					    andNItems: nitems];
	
	return ret;
}
@end
