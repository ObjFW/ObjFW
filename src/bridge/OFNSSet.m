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

#import <Foundation/NSSet.h>

#import "OFNSSet.h"
#import "NSEnumerator+OFObject.h"

#import "OFOFToNSBridging.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFNSSet
- (instancetype)initWithNSSet: (NSSet *)set
{
	self = [super init];

	@try {
		if (set == nil)
			@throw [OFInvalidArgumentException exception];

		_set = [set retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_set release];

	[super dealloc];
}

- (bool)containsObject: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	if ([(id <OFObject>)object conformsToProtocol:
	    @protocol(OFOFToNSBridging)])
		object = [object NSObject];

	ret = [_set containsObject: object];

	objc_autoreleasePoolPop(pool);
	return ret;
}

- (size_t)count
{
	return _set.count;
}

- (OFEnumerator *)objectEnumerator
{
	return [_set objectEnumerator].OFObject;
}
@end
