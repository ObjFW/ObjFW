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

#import "plugin/TestPlugin.h"

@interface OFModuleTests: OTTestCase
@end

@implementation OFModuleTests
- (void)testModule
{
	TestPlugin *test = nil;
	OFString *path;
	OFModule *module;
	Class (*class)(void);

#ifndef OF_IOS
	path = [OFModule pathForPluginWithName: @"plugin/TestPlugin"];
#else
	path = [OFModule pathForPluginWithName: @"PlugIns/TestPlugin"];
#endif
	OTAssertNotNil(path);

	module = [OFModule moduleWithPath: path];
	OTAssertNotNil(module);

	class = (Class (*)(void))(uintptr_t)[module addressForSymbol: @"class"];
	OTAssert(class != NULL);

	@try {
		test = [[class() alloc] init];
		OTAssertEqual([test test: 1234], 2468);
	} @finally {
		objc_release(test);
	}
}
@end
