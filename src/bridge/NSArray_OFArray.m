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

#import "NSArray_OFArray.h"
#import "OFArray.h"
#import "OFBridging.h"

#import "OFOutOfRangeException.h"

@implementation NSArray_OFArray
- initWithOFArray: (OFArray*)array_
{
	if ((self = [super init]) != nil) {
		@try {
			array = [array_ retain];
		} @catch (id e) {
			return nil;
		}
	}

	return self;
}

- (id)objectAtIndex: (NSUInteger)index
{
	id object = [array objectAtIndex: index];

	if ([object conformsToProtocol: @protocol(OFBridging)])
		return [object NSObject];

	return object;
}

- (NSUInteger)count
{
	size_t count = [array count];

	if (count > NSUIntegerMax)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	return (NSUInteger)count;
}
@end
