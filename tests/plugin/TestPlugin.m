/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "TestPlugin.h"

#ifdef OF_OBJFW_RUNTIME
# import "runtime/private.h"

OF_DESTRUCTOR()
{
	Class class = objc_getClass("TestPlugin");

	if (class == Nil)
		/*
		 * musl has broken dlclose(): Instead of calling the destructor
		 * on dlclose(), they call it on exit(). This of course means
                 * that our tests might have already called objc_deinit() and
                 * the class is already gone.
		 */
		return;

	objc_unregisterClass(class);
}
#endif

@implementation TestPlugin
- (int)test: (int)num
{
	return num * 2;
}
@end

Class
class(void)
{
	return [TestPlugin class];
}
