/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFPlugin.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

#import "plugin/TestPlugin.h"

static OFString *module = @"OFPlugin";

@implementation TestsAppDelegate (OFPluginTests)
- (void)pluginTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	TestPlugin *plugin;

	TEST(@"+[pluginFromFile:]",
	    (plugin = [OFPlugin pluginFromFile: @"plugin/TestPlugin"]))

	TEST(@"TestPlugin's -[test:]", [plugin test: 1234] == 2468)

	[pool drain];
}
@end
