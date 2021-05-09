/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
