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

#import "OFASN1BMPString.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidEncodingException.h"

@implementation OFASN1BMPString
- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberBMPString];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *DEREncodedContents;
	@try {
		const OFChar16 *UTF16String =
		    [string UTF16StringWithByteOrder: OFByteOrderBigEndian];
		DEREncodedContents = [OFData
		    dataWithItems: UTF16String
			    count: string.UTF16StringLength * 2];
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
		if (DEREncodedContents.count % 2 != 0)
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

	if ((uintptr_t)items % 2 == 0)
		return [OFString stringWithUTF16String: items
						length: count / 2
					     byteOrder: OFByteOrderBigEndian];

	OFChar16 *copy = OFAllocMemory(_DEREncodedContents.count / 2, 2);
	OFString *ret;
	@try {
		OFCopyMemory(copy, items, count);
		ret = [OFString stringWithUTF16String: copy
					       length: count / 2
					    byteOrder: OFByteOrderBigEndian];
	} @finally {
		OFFreeMemory(copy);
	}

	return ret;
}
@end
