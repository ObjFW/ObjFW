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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFThreadTests: OTTestCase
@end

@interface TestThread: OFThread
@end

@implementation TestThread
- (id)main
{
	[[OFThread threadDictionary] setObject: @"bar" forKey: @"foo"];
	OFEnsure([[[OFThread threadDictionary]
	    objectForKey: @"foo"] isEqual: @"bar"]);

	return @"success";
}
@end

@implementation OFThreadTests
- (void)testThread
{
	TestThread *thread = [TestThread thread];

	[thread start];

	OTAssertEqualObjects([thread join], @"success");
	OTAssertNil([[OFThread threadDictionary] objectForKey: @"foo"]);
}
@end
