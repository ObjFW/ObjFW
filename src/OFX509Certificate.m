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

#import "OFX509Certificate.h"
#import "OFASN1Sequence.h"

#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"

@implementation OFX509Certificate
@synthesize ASN1Value = _ASN1Value, privateKeyASN1Value = _privateKeyASN1Value;

+ (bool)supportsPEMFiles
{
	return true;
}

+ (bool)supportsPKCS12Files
{
	return false;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (OFString *)passphrase
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)certificateWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithASN1Value: ASN1Value]);
}

+ (instancetype)certificateWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
		     privateKeyASN1Value: (OF_KINDOF(OFASN1Value *))
					      privateKeyASN1Value
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithASN1Value: ASN1Value
			privateKeyASN1Value: privateKeyASN1Value]);
}

- (instancetype)initWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
{
	return [self initWithASN1Value: ASN1Value privateKeyASN1Value: nil];
}

- (instancetype)initWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
	      privateKeyASN1Value: (OF_KINDOF(OFASN1Value *))privateKeyASN1Value
{
	self = [super init];

	@try {
		if (![ASN1Value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];

		if (privateKeyASN1Value != nil && ![privateKeyASN1Value
		    isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];

		_ASN1Value = objc_retain(ASN1Value);
		_privateKeyASN1Value = objc_retain(privateKeyASN1Value);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_ASN1Value);
	objc_release(_privateKeyASN1Value);

	[super dealloc];
}
@end
