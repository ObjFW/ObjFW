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

#import "OFX500RelativeDistinguishedName.h"
#import "OFASN1Sequence.h"
#import "OFArray.h"
#import "OFX500AttributeTypeAndValue.h"

#import "OFInvalidFormatException.h"

@implementation OFX500RelativeDistinguishedName
- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFMutableArray *ATAVs;
	@try {
		if (components.count == 0)
			@throw [OFInvalidFormatException exception];

		ATAVs = [OFMutableArray arrayWithCapacity: components.count];

		for (OF_KINDOF(OFASN1Value *) component in components) {
			if (![component isKindOfClass: [OFASN1Sequence class]])
				@throw [OFInvalidFormatException exception];

			component = [component parsedAs:
			    [OFX500AttributeTypeAndValue class]];
			[ATAVs addObject: component];
		}

		[ATAVs makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [super initWithComponents: ATAVs
				tagClass: tagClass
			       tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (OFArray OF_GENERIC(OFX500AttributeTypeAndValue *) *)attributeTypesAndValues
{
	return (OFArray *)_components;
}
@end
