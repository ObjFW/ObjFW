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

	@try {
		name = [name_ copy];
		ns = [ns_ copy];
		stringValue = [value copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

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

- (BOOL)isEqual: (id)object
{
	OFXMLAttribute *other;

	if (![object isKindOfClass: [OFXMLAttribute class]])
		return NO;

	other = object;

	if (![other->name isEqual: name])
		return NO;
	if (other->ns != ns && ![other->ns isEqual: ns])
		return NO;
	if (![other->stringValue isEqual: stringValue])
		return NO;

	return YES;
}
@end
