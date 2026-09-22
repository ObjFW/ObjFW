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

#import "OFX509Extension.h"
#import "OFASN1Boolean.h"
#import "OFASN1ObjectIdentifier.h"
#import "OFASN1OctetString.h"
#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFX509Extension: OFASN1Sequence
@synthesize extensionID = _extensionID, critical = _critical;
@synthesize extensionValue = _extensionValue;

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

		if (components.count < 2 || components.count > 3)
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1ObjectIdentifier class]])
			@throw [OFInvalidFormatException exception];
		_extensionID = objc_retain(value);

		value = [enumerator nextObject];
		if ([value isKindOfClass: [OFASN1Boolean class]]) {
			if (![value boolValue])
				@throw [OFInvalidFormatException exception];

			_critical = true;
			value = [enumerator nextObject];
		}

		if (![value isKindOfClass: [OFASN1OctetString class]])
			@throw [OFInvalidFormatException exception];
		_extensionValue = objc_retain([value octets]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_extensionID);
	objc_release(_extensionValue);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tExtension ID = %@\n"
	    @"\tCritical = %@\n"
	    @"\tExtension value = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _extensionID,
	    (_critical ? @"true" : @"false"), _extensionValue];
}
@end
