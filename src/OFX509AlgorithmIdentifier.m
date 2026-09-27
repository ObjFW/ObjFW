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

#import "OFX509AlgorithmIdentifier.h"
#import "OFASN1ObjectIdentifier.h"
#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFX509AlgorithmIdentifier
@synthesize algorithm = _algorithm, parameters = _parameters;

+ (OFASN1ObjectIdentifier *)SHA256WithRSAEncryptionOID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.113549.1.1.11"];
}

+ (OFASN1ObjectIdentifier *)SHA384WithRSAEncryptionOID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.113549.1.1.12"];
}

+ (OFASN1ObjectIdentifier *)SHA512WithRSAEncryptionOID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.113549.1.1.13"];
}

+ (OFASN1ObjectIdentifier *)SHA224WithRSAEncryptionOID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.113549.1.1.14"];
}

+ (OFASN1ObjectIdentifier *)ECDSAWithSHA224OID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.10045.4.3.1"];
}

+ (OFASN1ObjectIdentifier *)ECDSAWithSHA256OID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.10045.4.3.2"];
}

+ (OFASN1ObjectIdentifier *)ECDSAWithSHA384OID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.10045.4.3.3"];
}

+ (OFASN1ObjectIdentifier *)ECDSAWithSHA512OID
{
	return [OFASN1ObjectIdentifier
	    identifierWithString: @"1.2.840.10045.4.3.4"];
}

+ (OFASN1ObjectIdentifier *)Ed25519OID
{
	return [OFASN1ObjectIdentifier identifierWithString: @"1.3.101.112"];
}

+ (OFASN1ObjectIdentifier *)Ed448OID
{
	return [OFASN1ObjectIdentifier identifierWithString: @"1.3.101.113"];
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

		if (components.count < 1 || components.count > 2)
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1ObjectIdentifier class]])
			@throw [OFInvalidFormatException exception];
		_algorithm = objc_retain(value);

		_parameters = objc_retain([enumerator nextObject]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_algorithm);
	objc_release(_parameters);

	[super dealloc];
}
@end
