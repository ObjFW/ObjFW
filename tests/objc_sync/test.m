/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
