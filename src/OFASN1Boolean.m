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

#import "OFASN1Boolean.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"

@implementation OFASN1Boolean
+ (instancetype)booleanWithBool: (bool)bool_
{
	return objc_autoreleaseReturnValue([[self alloc] initWithBool: bool_]);
}

+ (instancetype)booleanWithBool: (bool)bool_
		       tagClass: (OFASN1TagClass)tagClass
		      tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithBool: bool_
		tagClass: tagClass
	       tagNumber: tagNumber]);
}

- (instancetype)initWithBool: (bool)bool_
{
	return [self initWithBool: bool_
			 tagClass: OFASN1TagClassUniversal
			tagNumber: OFASN1TagNumberBoolean];
}

- (instancetype)initWithBool: (bool)bool_
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFData *rawValue;
	@try {
		rawValue = [OFData dataWithItems: (bool_ ? "\xFF" : "")
					   count: 1];
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
		if (rawValue.count != 1)
			@throw [OFInvalidFormatException exception];

		unsigned char value =
		    *(unsigned char *)[rawValue itemAtIndex: 0];
		if (value != 0 && value != 0xFF)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (bool)boolValue
{
	return *(unsigned char *)[_rawValue itemAtIndex: 0];
}
@end
