/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "NSArray_OFArray.h"
#import "OFArray.h"
#import "OFBridging.h"

#import "OFOutOfRangeException.h"

@implementation NSArray_OFArray
- initWithOFArray: (OFArray *)array
{
	if ((self = [super init]) != nil) {
		@try {
			_array = [array retain];
		} @catch (id e) {
			return nil;
		}
	}

	return self;
}

- (id)objectAtIndex: (NSUInteger)idx
{
	id object = [_array objectAtIndex: idx];

	if ([(OFObject *)object conformsToProtocol: @protocol(OFBridging)])
		return [object NSObject];

	return object;
}

- (NSUInteger)count
{
	size_t count = [_array count];

	if (count > NSUIntegerMax)
		@throw [OFOutOfRangeException exception];

	return (NSUInteger)count;
}
@end
