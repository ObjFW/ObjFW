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
		const OFUnichar *characters = string.characters;
		size_t length = string.length;

		for (size_t i = 0; i < length; i++) {
			OFUnichar c = characters[i];

			if (c / CHAR_BIT >= _size) {
				size_t newSize;

				if (UINT32_MAX - c < 1)
					@throw [OFOutOfRangeException
					    exception];

				newSize = OFRoundUpToPowerOf2(CHAR_BIT, c + 1) /
				    CHAR_BIT;

				_bitset = OFResizeMemory(_bitset, newSize, 1);
				memset(_bitset + _size, '\0', newSize - _size);

				_size = newSize;
			}

			OFBitsetSet(_bitset, c);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_bitset);

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	if (character / CHAR_BIT >= _size)
		return false;

	return OFBitsetIsSet(_bitset, character);
}
@end
