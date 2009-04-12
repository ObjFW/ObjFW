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

#import "OFAutoreleasePool.h"

#import <stdio.h>

#ifndef _WIN32
#define ZD "%zd"
#else
#define ZD "%u"
#endif

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
       
	ret = init(self, @selector(init));
	printf("New %s with retain cnt " ZD "\n", [self name],
	    [ret retainCount]);

	return ret;
}

- retain
{
	id ret;

	ret = retain(self, @selector(retain));
	printf("Retaining %s to " ZD "\n", [self name], [ret retainCount]);

	return ret;
}

- (void)release
{
	printf("Releasing %s to " ZD "\n", [self name], [self retainCount] - 1);

	release(self, @selector(release));
}
@end

int
main()
{
	init    = [OFObject replaceMethod: @selector(init)
		      withMethodFromClass: [TestObject class]];
	retain  = [OFObject replaceMethod: @selector(retain)
		      withMethodFromClass: [TestObject class]];
	release = [OFObject replaceMethod: @selector(release)
		      withMethodFromClass: [TestObject class]];

	OFObject *o1, *o2, *o3;
	OFAutoreleasePool *pool1, *pool2;

	o1 = [[OFObject new] autorelease];

	pool1 = [OFAutoreleasePool new];
	o2 = [[OFObject new] autorelease];
	[pool1 releaseObjects];

	o2 = [[OFObject new] autorelease];

	pool2 = [OFAutoreleasePool new];
	o3 = [[OFObject new] autorelease];

	[pool1 release];
	[o3 free];

	return 0;
}
