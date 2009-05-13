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

#import "OFAutoreleasePool.h"

#ifndef _WIN32
#define ZD "%zd"
#else
#define ZD "%u"
#endif

int inits;
int retains;
int releases;

IMP init;
IMP retain;
IMP release;

@interface TestObject: OFObject
- init;
- retain;
- (void)release;
@end

@implementation TestObject
- init
{
	id ret;

	inits++;
       
	ret = init(self, _cmd);
	printf("New %s with retain cnt " ZD "\n", [self name],
	    [ret retainCount]);

	return ret;
}

- retain
{
	id ret;

	retains++;

	ret = retain(self, _cmd);
	printf("Retaining %s to " ZD "\n", [self name], [ret retainCount]);

	return ret;
}

- (void)release
{
	releases++;

	printf("Releasing %s to " ZD "\n", [self name], [self retainCount] - 1);
	release(self, _cmd);
}
@end

int
main()
{
	inits = retains = releases = 0;

	init    = [OFObject replaceMethod: @selector(init)
		      withMethodFromClass: [TestObject class]];
	retain  = [OFObject replaceMethod: @selector(retain)
		      withMethodFromClass: [TestObject class]];
	release = [OFObject replaceMethod: @selector(release)
		      withMethodFromClass: [TestObject class]];

	OFObject *o1, *o2, *o3;
	OFAutoreleasePool *pool1, *pool2;

	o1 = [[[OFObject alloc] init] autorelease];

	pool1 = [[OFAutoreleasePool alloc] init];
	o2 = [[[OFObject alloc] init] autorelease];
	[pool1 releaseObjects];

	o2 = [[[OFObject alloc] init] autorelease];

	pool2 = [[OFAutoreleasePool alloc] init];
	o3 = [[[OFObject alloc] init] autorelease];

	[pool1 release];

	return (inits == 20 && retains == 5 && releases == 16 ? 0 : 1);
}
