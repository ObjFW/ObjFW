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

#import "plugin/TestPlugin.h"

@interface OFPluginTests: OTTestCase
@end

@implementation OFPluginTests
- (void)testPlugin
{
	OFString *path;
	OFPlugin *plugin;
	Class (*class)(void);
	TestPlugin *test;

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
