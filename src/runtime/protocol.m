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

	objc_globalMutex_lock();

	if ((categories = objc_categoriesForClass(class)) == NULL) {
		objc_globalMutex_unlock();
		return false;
	}

	for (long i = 0; categories[i] != NULL; i++) {
		for (struct objc_protocol_list *protocolList =
		    categories[i]->protocols; protocolList != NULL;
		    protocolList = protocolList->next) {
			for (long j = 0; j < protocolList->count; j++) {
				if (protocol_conformsToProtocol(
				    protocolList->list[j], protocol)) {
					objc_globalMutex_unlock();
					return true;
				}
			}
		}
	}

	objc_globalMutex_unlock();

	return false;
}
