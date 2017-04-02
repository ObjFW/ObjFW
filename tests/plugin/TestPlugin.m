/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#import "TestPlugin.h"

#ifdef OF_OBJFW_RUNTIME
# import "runtime-private.h"

OF_DESTRUCTOR()
{
	objc_unregister_class(objc_getClass("TestPlugin"));
}
#endif

@implementation TestPlugin
- (int)test: (int)num
{
	return num * 2;
}
@end

id
init_plugin(void)
{
	return [[[TestPlugin alloc] init] autorelease];
}
