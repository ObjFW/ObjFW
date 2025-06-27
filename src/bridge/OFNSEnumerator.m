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

#import <Foundation/NSEnumerator.h>

#import "OFNSEnumerator.h"

#import "OFNSToOFBridging.h"
#import "OFOFToNSBridging.h"

#import "OFInvalidArgumentException.h"

@implementation OFNSEnumerator
- (instancetype)initWithNSEnumerator: (NSEnumerator *)enumerator
{
	self = [super init];

	@try {
		if (enumerator == nil)
			@throw [OFInvalidArgumentException exception];

		_enumerator = objc_retain(enumerator);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

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

	if ([(id <NSObject>)object conformsToProtocol:
	    @protocol(OFNSToOFBridging)])
		return [object OFObject];

	return object;
}
@end
