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

#import "ObjFWRT.h"
#import "private.h"

void
__objc_exec_class(struct _objc_module *module)
{
	_objc_globalMutex_lock();

	_objc_registerAllSelectors(module->symtab);
	_objc_registerAllClasses(module->symtab);
	_objc_registerAllCategories(module->symtab);
	_objc_initStaticInstances(module->symtab);

	_objc_globalMutex_unlock();
}

void
objc_deinit(void)
{
	_objc_globalMutex_lock();

	_objc_unregisterAllCategories();
	_objc_unregisterAllClasses();
	_objc_unregisterAllSelectors();
	_objc_forgetPendingStaticInstances();
	_objc_dtable_cleanup();

	_objc_globalMutex_unlock();
}
