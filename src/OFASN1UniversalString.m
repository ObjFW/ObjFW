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

#import "OFASN1UniversalString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidEncodingException.h"

@implementation OFASN1UniversalString
- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberUniversalString];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *DEREncodedContents;
	@try {
		const OFChar32 *UTF32String =
		    [string UTF32StringWithByteOrder: OFByteOrderBigEndian];
		DEREncodedContents = [OFData dataWithItems: UTF32String
						     count: string.length * 4];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: tagClass
				      tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];

	@try {
		if (DEREncodedContents.count % 4 != 0)
			@throw [OFInvalidEncodingException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFString *)stringValue
{
	const void *items = _DEREncodedContents.items;
	size_t count = _DEREncodedContents.count;

	if ((uintptr_t)items % 4 == 0)
		return [OFString stringWithUTF32String: items
						length: count / 4
					     byteOrder: OFByteOrderBigEndian];

	OFChar32 *copy = OFAllocMemory(_DEREncodedContents.count / 4, 4);
	OFString *ret;
	@try {
		OFCopyMemory(copy, items, count);
		ret = [OFString stringWithUTF32String: copy
					       length: count / 4
					    byteOrder: OFByteOrderBigEndian];
	} @finally {
		OFFreeMemory(copy);
	}

	return ret;
}
@end
