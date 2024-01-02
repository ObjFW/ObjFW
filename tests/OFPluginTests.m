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

#import "TestsAppDelegate.h"

#import "plugin/TestPlugin.h"

#ifndef OF_IOS
static OFString *const pluginName = @"plugin/TestPlugin";
#else
static OFString *const pluginName = @"PlugIns/TestPlugin";
#endif

static OFString *const module = @"OFPlugin";

@implementation TestsAppDelegate (OFPluginTests)
- (void)pluginTests
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	OFPlugin *plugin;
	Class (*class)(void);
	TestPlugin *test;

	TEST(@"+[pathForName:]", (path = [OFPlugin pathForName: pluginName]))

	TEST(@"+[pluginWithPath:]", (plugin = [OFPlugin pluginWithPath: path]))

	TEST(@"-[addressForSymbol:]",
	    (class = (Class (*)(void))(uintptr_t)
	    [plugin addressForSymbol: @"class"]))

	test = [[class() alloc] init];
	@try {
		TEST(@"TestPlugin's -[test:]", [test test: 1234] == 2468)
	} @finally {
		[test release];
	}

	objc_autoreleasePoolPop(pool);
}
@end
