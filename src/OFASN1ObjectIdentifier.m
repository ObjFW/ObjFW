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

#include "config.h"

#import "OFASN1ObjectIdentifier.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFASN1ObjectIdentifier
@synthesize subidentifiers = _subidentifiers;

+ (instancetype)objectIdentifierWithSubidentifiers:
    (OFArray OF_GENERIC(OFNumber *) *)subidentifiers
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithSubidentifiers: subidentifiers]);
}

- (instancetype)initWithSubidentifiers:
    (OFArray OF_GENERIC(OFNumber *) *)subidentifiers
{
	self = [super init];

	@try {
		if (subidentifiers.count < 1)
			@throw [OFInvalidFormatException exception];

		switch ([[subidentifiers objectAtIndex: 0] longLongValue]) {
		case 0:
		case 1:
		case 2:
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		_subidentifiers = [subidentifiers copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
		     constructed: (bool)constructed
	      DEREncodedContents: (OFData *)DEREncodedContents
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray OF_GENERIC(OFNumber *) *subidentifiers;

	@try {
		const unsigned char *items = DEREncodedContents.items;
		size_t count = DEREncodedContents.count;
		unsigned long long value = 0;
		uint_fast8_t bits = 0;

		if (tagClass != OFASN1TagClassUniversal ||
		    tagNumber != OFASN1TagNumberObjectIdentifier || constructed)
			@throw [OFInvalidArgumentException exception];

		if (DEREncodedContents.itemSize != 1 || count == 0)
			@throw [OFInvalidArgumentException exception];

		subidentifiers = [OFMutableArray array];

		for (size_t i = 0; i < count; i++) {
			if (bits == 0 && items[i] == 0x80)
				@throw [OFInvalidFormatException exception];

			value = (value << 7) | (items[i] & 0x7F);
			bits += 7;

			if (bits > sizeof(unsigned long long) * 8)
				@throw [OFOutOfRangeException exception];

			if (items[i] & 0x80)
				continue;

			if (subidentifiers.count == 0) {
				if (value < 40)
					[subidentifiers addObject:
					    [OFNumber numberWithInt: 0]];
				else if (value < 80) {
					[subidentifiers addObject:
					    [OFNumber numberWithInt: 1]];
					value -= 40;
				} else {
					[subidentifiers addObject:
					    [OFNumber numberWithInt: 2]];
					value -= 80;
				}
			}

			[subidentifiers addObject:
			    [OFNumber numberWithUnsignedLongLong: value]];

			value = 0;
			bits = 0;
		}

		if (items[count - 1] & 0x80)
			@throw [OFInvalidFormatException exception];

		[subidentifiers makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithSubidentifiers: subidentifiers];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_subidentifiers);

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFASN1ObjectIdentifier *objectIdentifier;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFASN1ObjectIdentifier class]])
		return false;

	objectIdentifier = object;

	if (![objectIdentifier->_subidentifiers isEqual: _subidentifiers])
		return false;

	return true;
}

- (unsigned long)hash
{
	return _subidentifiers.hash;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFASN1ObjectIdentifier: %@>",
	    [_subidentifiers componentsJoinedByString: @"."]];
}
@end
