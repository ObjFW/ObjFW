/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include "config.h"

#import "OFBitSetCharacterSet.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFBitSetCharacterSet
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithCharactersInString: (OFString *)string
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		const of_unichar_t *characters = string.characters;
		size_t length = string.length;

		for (size_t i = 0; i < length; i++) {
			of_unichar_t c = characters[i];

			if (c / 8 >= _size) {
				size_t newSize;

				if (UINT32_MAX - c < 1)
					@throw [OFOutOfRangeException
					    exception];

				newSize = OF_ROUND_UP_POW2(8, c + 1) / 8;

				_bitset = [self resizeMemory: _bitset
							size: newSize];
				memset(_bitset + _size, '\0', newSize - _size);

				_size = newSize;
			}

			of_bitset_set(_bitset, c);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character / 8 >= _size)
		return false;

	return of_bitset_isset(_bitset, character);
}
@end
