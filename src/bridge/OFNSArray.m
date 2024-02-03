/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import <Foundation/NSArray.h>

#import "OFNSArray.h"
#import "NSBridging.h"

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

	if ([(NSObject *)object conformsToProtocol: @protocol(NSBridging)])
		return [object OFObject];

	return object;
}

- (size_t)count
{
	return _array.count;
}
@end
