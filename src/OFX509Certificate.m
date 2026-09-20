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
#import "OFPair.h"
#import "OFStream.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

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

static void
parsePEM(OFStream *stream, void (*callback)(OFString *, OFData *, void *ctx),
    void *ctx)
{
	OFString *section = nil;
	OFMutableString *string = nil;

	OFString *line;
	while ((line = [stream readLine]) != nil) {
		if (section != nil) {
			if ([line hasPrefix: @"-----END "]) {
				if (![line hasSuffix: @"-----"])
					@throw [OFInvalidFormatException
					    exception];

				if (![[line substringWithRange:
				    OFMakeRange(9, line.length - 9 - 5)]
				    isEqual: section])
					@throw [OFInvalidFormatException
					    exception];

				OFData *data = [OFData
				    dataWithBase64EncodedString: string];
				callback(section, data, ctx);

				section = nil;
				string = nil;

				continue;
			}

			[string appendString: line];
		} else {
			if ([line hasPrefix: @"-----BEGIN "]) {
				if (![line hasSuffix: @"-----"])
					@throw [OFInvalidFormatException
					    exception];

				section = [line substringWithRange:
				    OFMakeRange(11, line.length - 11 - 5)];
				string = [OFMutableString string];
			}
		}
	}

	if (section != nil)
		@throw [OFInvalidFormatException exception];
}

static void
parsePrivateKeyCallback(OFString *section, OFData *data, void *ctx)
{
	if (![section isEqual: @"PRIVATE KEY"])
		@throw [OFInvalidArgumentException exception];

	OF_KINDOF(OFASN1Value *) *privateKey = ctx;
	*privateKey = data.valueByParsingDER;
}

static void
parseCertificates(OFString *section, OFData *data, void *ctx)
{
	if (![section isEqual: @"CERTIFICATE"])
		@throw [OFInvalidArgumentException exception];

	OFPair *pair = ctx;
	OFMutableArray *certificateChain = pair.firstObject;
	OF_KINDOF(OFASN1Value *) privateKeyASN1Value;

	if (certificateChain.count == 0)
		privateKeyASN1Value = pair.secondObject;
	else
		privateKeyASN1Value = nil;

	[certificateChain addObject:
	    [OFX509Certificate certificateWithASN1Value: data.valueByParsingDER
				    privateKeyASN1Value: privateKeyASN1Value]];
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	OFMutableArray *certificateChain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OF_KINDOF(OFASN1Value *) privateKey = nil;

	if (privateKeyIRI != nil)
		parsePEM([OFIRIHandler openItemAtIRI: privateKeyIRI
						mode: @"r"],
		    parsePrivateKeyCallback, &privateKey);

	parsePEM([OFIRIHandler openItemAtIRI: certificatesIRI
					mode: @"r"],
	    parseCertificates, [OFPair pairWithFirstObject: certificateChain
					      secondObject: privateKey]);

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

- (int)version
{
	OFASN1Sequence *TBSCert = [_ASN1Value.components objectAtIndex: 0];
	if (![TBSCert isKindOfClass: [OFASN1Sequence class]])
		@throw [OFInvalidFormatException exception];

	for (OFConstructedASN1Value *value in TBSCert.components) {
		if (value.tagClass != OFASN1TagClassContextSpecific ||
		    value.tagNumber != 0)
			continue;

		if (![value isKindOfClass: [OFConstructedASN1Value class]] ||
		    value.components.count != 1)
			@throw [OFInvalidFormatException exception];

		OFASN1Integer *version = [value.components objectAtIndex: 0];
		if (![version isKindOfClass: [OFASN1Integer class]])
			@throw [OFInvalidFormatException exception];

		switch (version.longLongValue) {
		case 0:
			return 1;
		case 1:
			return 2;
		case 2:
			return 3;
		default:
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: [OFString stringWithFormat:
			    @"%lld", version.longLongValue]];
		}
	}

	@throw [OFInvalidFormatException exception];
}

- (OFASN1Integer *)serialNumber
{
	OFASN1Sequence *TBSCert = [_ASN1Value.components objectAtIndex: 0];
	if (![TBSCert isKindOfClass: [OFASN1Sequence class]])
		@throw [OFInvalidFormatException exception];

	OFASN1Integer *serialNumber;
	@try {
		serialNumber = [TBSCert.components objectAtIndex: 1];
	} @catch (OFOutOfRangeException *e) {
		@throw [OFInvalidFormatException exception];
	}

	if (![serialNumber isKindOfClass: [OFASN1Integer class]])
		@throw [OFInvalidFormatException exception];

	return serialNumber;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFX509Certificate:\n"
	    @"\tVersion = %d\n"
	    @"\tSerial number = %@\n"
	    @">",
	    self.version, self.serialNumber.rawValue];
}
@end
