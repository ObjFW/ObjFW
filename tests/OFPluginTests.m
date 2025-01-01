/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

@interface OFPluginTests: OTTestCase
@end

@implementation OFPluginTests
- (void)testPlugin
{
	TestPlugin *test = nil;
	OFString *path;
	OFPlugin *plugin;
	Class (*class)(void);

#ifndef OF_IOS
	path = [OFPlugin pathForName: @"plugin/TestPlugin"];
#else
	path = [OFPlugin pathForName: @"PlugIns/TestPlugin"];
#endif
	OTAssertNotNil(path);

	plugin = [OFPlugin pluginWithPath: path];
	OTAssertNotNil(plugin);

	class = (Class (*)(void))(uintptr_t)[plugin addressForSymbol: @"class"];
	OTAssert(class != NULL);

	@try {
		test = [[class() alloc] init];
		OTAssertEqual([test test: 1234], 2468);
	} @finally {
		[test release];
	}
}
@end
