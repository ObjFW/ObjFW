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

#import "OFX500AttributeTypeAndValue.h"
#import "OFASN1ObjectIdentifier.h"
#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFX500AttributeTypeAndValue
@synthesize attributeType = _attributeType, attributeValue = _attributeValue;

- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithComponents: components
				tagClass: tagClass
			       tagNumber: tagNumber];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (components.count != 2)
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1ObjectIdentifier class]])
			@throw [OFInvalidFormatException exception];
		_attributeType = objc_retain(value);

		value = [enumerator nextObject];
		_attributeValue = objc_retain(value);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_attributeType);
	objc_release(_attributeValue);

	[super dealloc];
}

- (OFString *)description
{
	OFString *attributeValue = [[_attributeValue description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tType = %@\n"
	    @"\tValue = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _attributeType,
	    attributeValue];
}
@end
