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

#import "OFObject.h"
#import "OFObject+Serialization.h"
#import "OFSerialization.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

int _OFObject_Serialization_reference;

@implementation OFObject (Serialization)
- (OFString*)stringBySerializing
{
	OFAutoreleasePool *pool;
	OFXMLElement *element;
	OFXMLElement *root;
	OFString *ret;

	if (![self conformsToProtocol: @protocol(OFSerialization)])
		@throw [OFNotImplementedException
		    exceptionWithClass: [self class]
			      selector: @selector(stringBySerializing)];

	pool = [[OFAutoreleasePool alloc] init];
	element = [(id)self XMLElementBySerializing];

	root = [OFXMLElement elementWithName: @"serialization"
				   namespace: OF_SERIALIZATION_NS];
	[root addAttributeWithName: @"version"
		       stringValue: @"0"];
	[root addChild: element];

	ret = [@"<?xml version='1.0' encoding='UTF-8'?>\n"
	    stringByAppendingString: [root XMLStringWithIndentation: 2]];

	[ret retain];
	[pool release];
	[ret autorelease];

	return ret;
}
@end
