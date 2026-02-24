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

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface RuntimeARCTests: OTTestCase
@end

@interface RuntimeARCTestClass: OFObject
@end

@implementation RuntimeARCTests
- (void)testExceptionsDuringInit
{
	OTAssertThrows((void)[[RuntimeARCTestClass alloc] init]);
}

- (void)testWeakReferences
{
	id object = [[OFObject alloc] init];
	__weak id weak1 = object;
	__weak id weak2 = object;

	OTAssertEqual(weak1, object);
	OTAssertEqual(weak2, object);

	object = nil;
	OTAssertNil(weak1);
	OTAssertNil(weak2);
}
@end

@implementation RuntimeARCTestClass
- (instancetype)init
{
	self = [super init];

#if defined(OF_WINDOWS) && defined(OF_AMD64)
	/*
	 * Clang has a bug on Windows where it creates an invalid call into
	 * objc_retainAutoreleasedReturnValue(). Work around it by not using an
	 * autoreleased exception.
	 */
	@throw [[OFException alloc] init];
#else
	@throw [OFException exception];
#endif

	return self;
}
@end
