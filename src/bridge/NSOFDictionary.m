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

#import "NSOFDictionary.h"
#import "OFDictionary.h"
#import "OFEnumerator+NSObject.h"

#import "NSBridging.h"
#import "OFBridging.h"

#import "OFOutOfRangeException.h"

@implementation NSOFDictionary
- (instancetype)initWithOFDictionary: (OFDictionary *)dictionary
{
	if ((self = [super init]) != nil)
		_dictionary = [dictionary retain];

	return self;
}

- (void)dealloc
{
	[_dictionary release];

	[super dealloc];
}

- (id)objectForKey: (id)key
{
	id object;

	if ([(NSObject *)key conformsToProtocol: @protocol(NSBridging)])
		key = [key OFObject];

	object = [_dictionary objectForKey: key];

	if ([(OFObject *)object conformsToProtocol: @protocol(OFBridging)])
		return [object NSObject];

	return object;
}

- (NSUInteger)count
{
	size_t count = _dictionary.count;

	if (count > NSUIntegerMax)
		@throw [OFOutOfRangeException exception];

	return (NSUInteger)count;
}

- (NSEnumerator *)keyEnumerator
{
	return [_dictionary keyEnumerator].NSObject;
}
@end
