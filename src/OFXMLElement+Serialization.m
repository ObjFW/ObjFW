/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
# import <objc/runtime.h>
#elif defined(OF_OLD_GNU_RUNTIME)
# import <objc/objc-api.h>
#endif

#import "OFXMLElement.h"
#import "OFXMLElement+Serialization.h"
#import "OFSerialization.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"

#if defined(OF_OBJFW_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
# define objc_lookUpClass objc_lookup_class
#endif

int _OFXMLElement_Serialization_reference;

@implementation OFXMLElement (Serialization)
- (id)objectByDeserializing
{
	OFAutoreleasePool *pool;
	Class class;
	id <OFSerialization> object;

	pool = [[OFAutoreleasePool alloc] init];

	if ((class = objc_lookUpClass([name cString])) == Nil)
		@throw [OFNotImplementedException newWithClass: Nil];

	if (![class conformsToProtocol: @protocol(OFSerialization)])
		@throw [OFNotImplementedException
		    newWithClass: class
			selector: @selector(initWithSerialization:)];

	object = [[class alloc] initWithSerialization: self];

	@try {
		[pool release];
	} @finally {
		[object autorelease];
	}

	return object;
}
@end
