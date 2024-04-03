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

#import "ObjFWRT.h"
#import "private.h"

void
__objc_exec_class(struct objc_module *module)
{
	objc_globalMutex_lock();

	objc_registerAllSelectors(module->symtab);
	objc_registerAllClasses(module->symtab);
	objc_registerAllCategories(module->symtab);
	objc_initStaticInstances(module->symtab);

	objc_globalMutex_unlock();
}

void
objc_deinit(void)
{
	objc_globalMutex_lock();

	objc_unregisterAllCategories();
	objc_unregisterAllClasses();
	objc_unregisterAllSelectors();
	objc_forgetPendingStaticInstances();
	objc_dtable_cleanup();

	objc_globalMutex_unlock();
}
