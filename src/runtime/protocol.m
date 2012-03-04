/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include <string.h>

#import "runtime.h"
#import "runtime-private.h"

@implementation Protocol
- (BOOL)_isImplementedByClass: (Class)cls
{
	struct objc_protocol_list *pl;
	struct objc_category **cats;
	long i, j;

	objc_global_mutex_lock();

	for (pl = cls->protocols; pl != NULL; pl = pl->next) {
		for (i = 0; i < pl->count; i++) {
			if (!strcmp(pl->list[i]->name, name)) {
				objc_global_mutex_unlock();
				return YES;
			}
		}
	}

	if ((cats = objc_categories_for_class(cls)) == NULL) {
		objc_global_mutex_unlock();
		return NO;
	}

	for (i = 0; cats[i] != NULL; i++) {
		for (pl = cats[i]->protocols; pl != NULL; pl = pl->next) {
			for (j = 0; j < pl->count; j++) {
				if (!strcmp(pl->list[j]->name, name)) {
					objc_global_mutex_unlock();
					return YES;
				}
			}
		}
	}

	objc_global_mutex_unlock();

	return NO;
}
@end

BOOL
class_conformsToProtocl(Class cls, Protocol *p)
{
	return [p _isImplementedByClass: cls];
}
