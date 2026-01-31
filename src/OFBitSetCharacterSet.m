/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

			if (c / OF_ULONG_BIT >= _size) {
				size_t newSize;

				if (UINT32_MAX - c < 1)
					@throw [OFOutOfRangeException
					    exception];

				newSize = OFRoundUpToPowerOf2(OF_ULONG_BIT,
				    c + 1) / OF_ULONG_BIT;

				_bitSet = OFResizeMemory(_bitSet, newSize,
				    sizeof(unsigned long));
				memset(_bitSet + _size, '\0',
				    (newSize - _size) * sizeof(unsigned long));

				_size = newSize;
			}

			OFBitSetSet(_bitSet, c);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_bitSet);

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	if (character / OF_ULONG_BIT >= _size)
		return false;

	return OFBitSetIsSet(_bitSet, character);
}
@end
