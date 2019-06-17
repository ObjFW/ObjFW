/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "ObjFWRT.h"
#import "private.h"

@implementation Protocol
@end

const char *
protocol_getName(Protocol *protocol)
{
	return protocol->name;
}

bool
protocol_isEqual(Protocol *protocol1, Protocol *protocol2)
{
	return (strcmp(protocol_getName(protocol1),
	    protocol_getName(protocol2)) == 0);
}

bool
protocol_conformsToProtocol(Protocol *protocol1, Protocol *protocol2)
{
	if (protocol_isEqual(protocol1, protocol2))
		return true;

	for (struct objc_protocol_list *protocolList = protocol1->protocolList;
	    protocolList != NULL; protocolList = protocolList->next)
		for (long i = 0; i < protocolList->count; i++)
			if (protocol_conformsToProtocol(protocolList->list[i],
			    protocol2))
				return true;

	return false;
}

bool
class_conformsToProtocol(Class class, Protocol *protocol)
{
	struct objc_category **categories;

	if (class == Nil)
		return false;

	for (struct objc_protocol_list *protocolList = class->protocols;
	    protocolList != NULL; protocolList = protocolList->next)
		for (long i = 0; i < protocolList->count; i++)
			if (protocol_conformsToProtocol(protocolList->list[i],
			    protocol))
				return true;

	objc_global_mutex_lock();

	if ((categories = objc_categories_for_class(class)) == NULL) {
		objc_global_mutex_unlock();
		return false;
	}

	for (long i = 0; categories[i] != NULL; i++) {
		for (struct objc_protocol_list *protocolList =
		    categories[i]->protocols; protocolList != NULL;
		    protocolList = protocolList->next) {
			for (long j = 0; j < protocolList->count; j++) {
				if (protocol_conformsToProtocol(
				    protocolList->list[j], protocol)) {
					objc_global_mutex_unlock();
					return true;
				}
			}
		}
	}

	objc_global_mutex_unlock();

	return false;
}
