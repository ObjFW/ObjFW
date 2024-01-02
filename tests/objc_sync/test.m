/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdio.h>

#import "OFString.h"
#import "OFThread.h"

OFObject *lock;

@interface MyThread: OFThread
@end

@implementation MyThread
- (id)main
{
	const char *name = [[[OFThread currentThread] name] UTF8String];

	printf("[%s] Entering #1\n", name);
	@synchronized (lock) {
		printf("[%s] Entering #2\n", name);
		@synchronized (lock) {
			printf("[%s] Hello!\n", name);
		}
		printf("[%s] Left #2\n", name);
	}
	printf("[%s] Left #1\n", name);

	return nil;
}
@end

int
main(void)
{
	MyThread *t1, *t2;

	lock = [[OFObject alloc] init];

	t1 = [MyThread thread];
	t1.name = @"A";

	t2 = [MyThread thread];
	t2.name = @"B";

	[t1 start];
	[t2 start];

	[t1 join];
	[t2 join];

	return 0;
}
