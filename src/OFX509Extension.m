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
#import "OFData.h"
#import "OFString.h"
#import "OFX509BasicConstraints.h"
#import "OFX509KeyUsage.h"

#import "OFInvalidFormatException.h"

@implementation OFX509Extension
@synthesize extensionID = _extensionID, critical = _critical;
@synthesize extensionValueData = _extensionValueData;
@synthesize extensionValue = _extensionValue;

+ (OFASN1ObjectIdentifier *)keyUsageOID
{
	return [OFASN1ObjectIdentifier identifierWithString: @"2.5.29.15"];
}

+ (OFASN1ObjectIdentifier *)basicConstraintsOID
{
	return [OFASN1ObjectIdentifier identifierWithString: @"2.5.29.19"];
}

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
		_extensionValueData = objc_retain([value octets]);

		if ([_extensionID isEqual: [OFX509Extension keyUsageOID]]) {
			value = _extensionValueData.valueByParsingDER;
			if (![value isKindOfClass: [OFASN1BitString class]])
				@throw [OFInvalidFormatException exception];

			_extensionValue = objc_retain(
			    [value parsedAs: [OFX509KeyUsage class]]);
		} else if ([_extensionID isEqual:
		    [OFX509Extension basicConstraintsOID]]) {
			value = _extensionValueData.valueByParsingDER;
			if (![value isKindOfClass: [OFASN1Sequence class]])
				@throw [OFInvalidFormatException exception];

			_extensionValue = objc_retain(
			    [value parsedAs: [OFX509BasicConstraints class]]);
		}

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
	objc_release(_extensionValueData);

	[super dealloc];
}

- (OFString *)description
{
	id extensionValue = [[_extensionValue description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tExtension ID = %@\n"
	    @"\tCritical = %@\n"
	    @"\tExtension %@ = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _extensionID,
	    (_critical ? @"true" : @"false"),
	    (extensionValue != nil ? @"value" : @"value data"),
	    (extensionValue != nil ? extensionValue : _extensionValueData)];
}
@end
