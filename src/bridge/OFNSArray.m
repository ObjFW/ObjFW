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

#import <Foundation/NSArray.h>

#import "OFNSArray.h"
#import "OFNSToOFBridging.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFNSArray
- (instancetype)initWithNSArray: (NSArray *)array
{
	self = [super init];

	@try {
		if (array == nil)
			@throw [OFInvalidArgumentException exception];

		_array = [array retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_array release];

	[super dealloc];
}

- (id)objectAtIndex: (size_t)idx
{
	id object;

	if (idx > NSUIntegerMax)
		@throw [OFOutOfRangeException exception];

	object = [_array objectAtIndex: idx];

	if ([(id <NSObject>)object conformsToProtocol:
	    @protocol(OFNSToOFBridging)])
		return [object OFObject];

	return object;
}

- (size_t)count
{
	return _array.count;
}
@end
