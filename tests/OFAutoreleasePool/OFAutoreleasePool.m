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

#import "OFAutoreleasePool.h"

/* FIXME: Just crashtests */

int
main()
{
	OFObject *o1, *o2, *o3;
	OFAutoreleasePool *pool1, *pool2;

	o1 = [[OFObject new] autorelease];

	pool1 = [OFAutoreleasePool new];
	o2 = [[OFObject new] autorelease];
	[pool1 release];

	o2 = [[OFObject new] autorelease];

	pool2 = [OFAutoreleasePool new];
	o3 = [[OFObject new] autorelease];

	[pool1 release];
	[o3 free];

	return 0;
}
