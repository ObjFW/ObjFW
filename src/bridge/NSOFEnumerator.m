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

#import "NSOFEnumerator.h"
#import "OFEnumerator.h"

#import "OFNSToOFBridging.h"
#import "OFOFToNSBridging.h"

@implementation NSOFEnumerator
- (instancetype)initWithOFEnumerator: (OFEnumerator *)enumerator
{
	if ((self = [super init]) != nil)
		_enumerator = objc_retain(enumerator);

	return self;
}

- (void)dealloc
{
	objc_release(_enumerator);

	[super dealloc];
}

- (id)nextObject
{
	id object = [_enumerator nextObject];

	if ([(id <OFObject>)object conformsToProtocol:
	    @protocol(OFOFToNSBridging)])
		return [object NSObject];

	return object;
}
@end
