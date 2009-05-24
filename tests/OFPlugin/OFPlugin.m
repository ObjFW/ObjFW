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

#import "OFPlugin.h"
#import "TestPlugin/TestPlugin.h"

int
main()
{
	TestPlugin *plugin;

	plugin = [OFPlugin pluginFromFile: @"TestPlugin/TestPlugin"];
	if ([plugin test: 1234] != 2468) {
		puts("\033[K\033[1;31mTest 1/1 failed!\033[m");
		return 1;
	}

	puts("\033[1;32mTests successful: 1/1\033[0m");
	return 0;
}
