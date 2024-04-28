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

#import "NSOFSet.h"
#import "OFEnumerator+NSObject.h"
#import "OFSet.h"

#import "OFBridging.h"
#import "NSBridging.h"

#import "OFOutOfRangeException.h"

@implementation NSOFSet
- (instancetype)initWithOFSet: (OFSet *)set
{
	if ((self = [super init]) != nil)
		_set = [set retain];

	return self;
}

- (void)dealloc
{
	[_set release];

	[super dealloc];
}

- (id)member: (id)object
{
	id originalObject = object;

	if ([(NSObject *)object conformsToProtocol: @protocol(NSBridging)])
		object = [object OFObject];

	if ([_set containsObject: object])
		return originalObject;

	return nil;
}

- (NSUInteger)count
{
	size_t count = _set.count;

	if (count > NSUIntegerMax)
		@throw [OFOutOfRangeException exception];

	return (NSUInteger)count;
}

- (NSEnumerator *)objectEnumerator
{
	return [_set objectEnumerator].NSObject;
}
@end
