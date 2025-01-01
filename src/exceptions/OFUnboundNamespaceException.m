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

#import "OFUnboundNamespaceException.h"
#import "OFString.h"
#import "OFXMLElement.h"

@implementation OFUnboundNamespaceException
@synthesize namespace = _namespace, element = _element;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithNamespace: (OFString *)namespace
			       element: (OFXMLElement *)element
{
	return [[[self alloc] initWithNamespace: namespace
					element: element] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithNamespace: (OFString *)namespace
			  element: (OFXMLElement *)element
{
	self = [super init];

	@try {
		_namespace = [namespace copy];
		_element = [element retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_namespace release];
	[_element release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The namespace %@ is not bound in an element of type %@!",
	    _namespace, _element.class];
}
@end
