/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFXMLAttribute.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

@implementation OFXMLAttribute
+ attributeWithName: (OFString*)name
	  namespace: (OFString*)ns
	stringValue: (OFString*)value
{
	return [[[self alloc] initWithName: name
				 namespace: ns
			       stringValue: value] autorelease];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns_
   stringValue: (OFString*)value
{
	self = [super init];

	name = [name_ copy];
	ns = [ns_ copy];
	stringValue = [value copy];

	return self;
}

- (void)dealloc
{
	[name release];
	[ns release];
	[stringValue release];

	[super dealloc];
}

- (OFString*)name
{
	return [[name copy] autorelease];
}

- (OFString*)namespace
{
	return [[ns copy] autorelease];
}

- (OFString*)stringValue
{
	return [[stringValue copy] autorelease];
}
@end
