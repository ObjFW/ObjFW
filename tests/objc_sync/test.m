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

#import "OFString.h"
#import "OFThread.h"

OFObject *lock;

@interface MyThread: OFThread
- main;
@end

@implementation MyThread
- main
{
	printf("[%s] Entering #1\n", [object cString]);
	@synchronized (lock) {
		printf("[%s] Entering #2\n", [object cString]);
		@synchronized (lock) {
			printf("[%s] Hello!\n", [object cString]);
		}
		printf("[%s] Left #2\n", [object cString]);
	}
	printf("[%s] Left #1\n", [object cString]);

	return nil;
}
@end

int
main()
{
	lock = [[OFObject alloc] init];
	MyThread *t1 = [MyThread threadWithObject: @"A"];
	MyThread *t2 = [MyThread threadWithObject: @"B"];

	[t1 start];
	[t2 start];

	[t1 join];
	[t2 join];

	return 0;
}
