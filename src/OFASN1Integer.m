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

#import "OFASN1Integer.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFASN1Integer
+ (instancetype)integerWithLongLong: (long long)value
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithLongLong: value]);
}

+ (instancetype)integerWithLongLong: (long long)value
			   tagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithLongLong: value
		    tagClass: tagClass
		   tagNumber: tagNumber]);
}

- (instancetype)initWithLongLong: (long long)value
{
	return [self initWithLongLong: value
			     tagClass: OFASN1TagClassUniversal
			    tagNumber: OFASN1TagNumberInteger];
}

- (instancetype)initWithLongLong: (long long)value
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *rawValue;
	@try {
		unsigned char buffer[8];
		size_t length = _OFDEREncodeInteger(value, buffer);
		rawValue = [OFData dataWithItems: buffer count: length];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithRawValue: rawValue
			     tagClass: tagClass
			    tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithRawValue: (OFData *)rawValue
{
	return [self initWithRawValue: rawValue
			     tagClass: OFASN1TagClassUniversal
			    tagNumber: OFASN1TagNumberInteger];
}

- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithRawValue: rawValue
			      tagClass: tagClass
			     tagNumber: tagNumber];

	@try {
		if (rawValue.itemSize != 1)
			@throw [OFInvalidArgumentException exception];

		size_t count = rawValue.count;
		if (count == 0)
			@throw [OFInvalidFormatException exception];

		if (count >= 2) {
			const unsigned char *items = rawValue.items;
			if ((items[0] == 0 && !(items[1] & 0x80)) ||
			    (items[0] == 0xFF && (items[1] & 0x80)))
				@throw [OFInvalidFormatException exception];
		}
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (long long)longLongValue
{
	return _OFDERDecodeInteger(_rawValue.items, _rawValue.count);
}
@end
