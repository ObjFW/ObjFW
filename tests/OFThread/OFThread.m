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

#include "config.h"

#include <stdio.h>

#import "OFThread.h"
#import "OFString.h"

@interface MyThread: OFThread
@end

@implementation MyThread
- main
{
	if ([object isEqual: @"foo"])
		return @"successful";

	return @"failed";
}
@end

int
main()
{
	MyThread *t = [MyThread threadWithObject: @"foo"];

	if (![[t join] isEqual: @"successful"]) {
		puts("Test failed!");
		return 1;
	}

	puts("Test successful!");
	return 0;
}
