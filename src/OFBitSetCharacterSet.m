/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
		const OFUnichar *characters = string.characters;
		size_t length = string.length;

		for (size_t i = 0; i < length; i++) {
			OFUnichar c = characters[i];

			if (c / CHAR_BIT >= _size) {
				size_t newSize;

				if (UINT32_MAX - c < 1)
					@throw [OFOutOfRangeException
					    exception];

				newSize = OF_ROUND_UP_POW2(CHAR_BIT, c + 1) /
				    CHAR_BIT;

				_bitset = of_realloc(_bitset, newSize, 1);
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

- (void)dealloc
{
	free(_bitset);

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	if (character / CHAR_BIT >= _size)
		return false;

	return of_bitset_isset(_bitset, character);
}
@end
