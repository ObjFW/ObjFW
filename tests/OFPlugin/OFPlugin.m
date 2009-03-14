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

#import "config.h"

#import "OFPlugin.h"
#import "TestPlugin/TestPlugin.h"

int
main()
{
	OFPlugin <TestPlugin> *plugin;

	plugin = [OFPlugin pluginFromFile: "TestPlugin/TestPlugin"];
	[plugin test];

	return 0;
}
