/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <string.h>

#import "ObjFW-RT.h"
#import "private.h"

@implementation Protocol
@end

const char *
protocol_getName(Protocol *p)
{
	return p->name;
}

bool
protocol_isEqual(Protocol *a, Protocol *b)
{
	return (strcmp(protocol_getName(a), protocol_getName(b)) == 0);
}

bool
protocol_conformsToProtocol(Protocol *a, Protocol *b)
{
	if (protocol_isEqual(a, b))
		return true;

	for (struct objc_protocol_list *pl = a->protocol_list;
	    pl != NULL; pl = pl->next)
		for (long i = 0; i < pl->count; i++)
			if (protocol_conformsToProtocol(pl->list[i], b))
				return true;

	return false;
}

bool
class_conformsToProtocol(Class cls, Protocol *p)
{
	struct objc_category **cats;

	if (cls == Nil)
		return false;

	for (struct objc_protocol_list *pl = cls->protocols;
	    pl != NULL; pl = pl->next)
		for (long i = 0; i < pl->count; i++)
			if (protocol_conformsToProtocol(pl->list[i], p))
				return true;

	objc_global_mutex_lock();

	if ((cats = objc_categories_for_class(cls)) == NULL) {
		objc_global_mutex_unlock();
		return false;
	}

	for (long i = 0; cats[i] != NULL; i++) {
		for (struct objc_protocol_list *pl = cats[i]->protocols;
		    pl != NULL; pl = pl->next) {
			for (long j = 0; j < pl->count; j++) {
				if (protocol_conformsToProtocol(
				    pl->list[j], p)) {
					objc_global_mutex_unlock();
					return true;
				}
			}
		}
	}

	objc_global_mutex_unlock();

	return false;
}
