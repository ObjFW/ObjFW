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

#import <Foundation/NSDictionary.h>

#import "OFNSDictionary.h"
#import "NSEnumerator+OFObject.h"

#import "OFNSToOFBridging.h"
#import "OFOFToNSBridging.h"

#import "OFInvalidArgumentException.h"

@implementation OFNSDictionary
- (instancetype)initWithNSDictionary: (NSDictionary *)dictionary
{
	self = [super init];

	@try {
		if (dictionary == nil)
			@throw [OFInvalidArgumentException exception];

		_dictionary = objc_retain(dictionary);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_dictionary);

	[super dealloc];
}

- (id)objectForKey: (id)key
{
	id object;

	if ([(id <OFObject>)key conformsToProtocol:
	    @protocol(OFOFToNSBridging)])
		key = [key NSObject];

	object = [_dictionary objectForKey: key];

	if ([(id <NSObject>)object conformsToProtocol:
	    @protocol(OFNSToOFBridging)])
		return [object OFObject];

	return object;
}

- (size_t)count
{
	return _dictionary.count;
}

- (OFEnumerator *)keyEnumerator
{
	return [_dictionary keyEnumerator].OFObject;
}
@end
