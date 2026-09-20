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
#import "OFASN1Integer.h"
#import "OFASN1Sequence.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFIRIHandler.h"
#import "OFPEMParser.h"
#import "OFPKCS8PrivateKey.h"
#import "OFPair.h"
#import "OFStream.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFX509Certificate
@synthesize ASN1Value = _ASN1Value;
@synthesize associatedPrivateKey = _associatedPrivateKey, version = _version;
@synthesize serialNumber = _serialNumber;

+ (bool)supportsPEMFiles
{
	return true;
}

+ (bool)supportsPKCS12Files
{
	return false;
}

static void
parsePrivateKeyCallback(OFString *section, OFData *data, void *ctx)
{
	if (![section isEqual: @"PRIVATE KEY"])
		@throw [OFInvalidArgumentException exception];

	OFPKCS8PrivateKey **privateKey = ctx;
	*privateKey =
	    [data.valueByParsingDER parsedAs: [OFPKCS8PrivateKey class]];
}

static void
parseCertificates(OFString *section, OFData *data, void *ctx)
{
	if (![section isEqual: @"CERTIFICATE"])
		@throw [OFInvalidArgumentException exception];

	OFPair *pair = ctx;
	OFMutableArray *certificateChain = pair.firstObject;
	OFPKCS8PrivateKey *associatedPrivateKey;

	if (certificateChain.count == 0)
		associatedPrivateKey = pair.secondObject;
	else
		associatedPrivateKey = nil;

	[certificateChain addObject:
	    [OFX509Certificate certificateWithASN1Value: data.valueByParsingDER
				   associatedPrivateKey: associatedPrivateKey]];
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	OFMutableArray *certificateChain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFPKCS8PrivateKey *associatedPrivateKey = nil;

	if (privateKeyIRI != nil)
		OFParsePEM([OFIRIHandler openItemAtIRI: privateKeyIRI
						  mode: @"r"],
		    parsePrivateKeyCallback, &associatedPrivateKey);

	OFParsePEM([OFIRIHandler openItemAtIRI: certificatesIRI
					mode: @"r"],
	    parseCertificates,
	    [OFPair pairWithFirstObject: certificateChain
			   secondObject: associatedPrivateKey]);

	objc_autoreleasePoolPop(pool);

	return certificateChain;
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
		    associatedPrivateKey: (OFPKCS8PrivateKey *)
					      associatedPrivateKey
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithASN1Value: ASN1Value
		       associatedPrivateKey: associatedPrivateKey]);
}

- (instancetype)initWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
{
	return [self initWithASN1Value: ASN1Value associatedPrivateKey: nil];
}

- (instancetype)initWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
	     associatedPrivateKey: (OFPKCS8PrivateKey *)associatedPrivateKey
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![ASN1Value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];

		_ASN1Value = objc_retain(ASN1Value);
		_associatedPrivateKey = objc_retain(associatedPrivateKey);

		if (_ASN1Value.components.count != 3)
			@throw [OFInvalidFormatException exception];

		OFASN1Sequence *TBSCert =
		    [_ASN1Value.components objectAtIndex: 0];
		if (![TBSCert isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator =
		    [TBSCert.components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if ([value tagClass] == OFASN1TagClassContextSpecific &&
		    [value tagNumber] == 0) {
			if (![value isKindOfClass:
			    [OFConstructedASN1Value class]])
				@throw [OFInvalidFormatException exception];

			OFConstructedASN1Value *constructed = value;
			if (constructed.components.count != 1)
				@throw [OFInvalidFormatException exception];

			OFASN1Integer *versionValue =
			    constructed.components.firstObject;
			if (![versionValue isKindOfClass:
			    [OFASN1Integer class]])
				@throw [OFInvalidFormatException exception];

			long long version;
			@try {
				version = versionValue.longLongValue;
			} @catch (OFOutOfRangeException *e) {
				@throw [OFUnsupportedVersionException
				    exceptionWithVersion:
				    versionValue.rawValue.description];
			}

			switch (version) {
			case 0:
				@throw [OFInvalidFormatException exception];
			case 1:
				_version = 2;
				break;
			case 2:
				_version = 3;
				break;
			default:
				@throw [OFUnsupportedVersionException
				    exceptionWithVersion:
				    versionValue.rawValue.description];
			}

			value = [enumerator nextObject];
		} else
			_version = 1;

		if (![value isKindOfClass: [OFASN1Integer class]])
			@throw [OFInvalidFormatException exception];

		_serialNumber = objc_retain(value);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_ASN1Value);
	objc_release(_associatedPrivateKey);
	objc_release(_serialNumber);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFX509Certificate:\n"
	    @"\tVersion = %d\n"
	    @"\tSerial number = %@\n"
	    @">",
	    _version, _serialNumber.rawValue];
}
@end
