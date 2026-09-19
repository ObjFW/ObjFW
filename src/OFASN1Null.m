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

#import "OFASN1Null.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Null
+ (instancetype)null
{
	return objc_autoreleaseReturnValue([[OFASN1Null alloc] init]);
}

+ (instancetype)nullWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[OFASN1Null alloc]
	    initWithTagClass: tagClass
		   tagNumber: tagNumber]);
}

- (instancetype)init
{
	return [self initWithTagClass: OFASN1TagClassUniversal
			    tagNumber: OFASN1TagNumberNull];
}

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *rawValue;
	@try {
		rawValue = [OFData data];
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
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithRawValue: rawValue
			      tagClass: tagClass
			     tagNumber: tagNumber];

	@try {
		if (rawValue.count != 0)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}
@end
