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
#import "OFX509Certificate+Private.h"
#import "OFASN1BitString.h"
#import "OFASN1Sequence.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFIRIHandler.h"
#import "OFPEMParser.h"
#import "OFPKCS8PrivateKey.h"
#import "OFPair.h"
#import "OFStream.h"
#import "OFX509AlgorithmIdentifier.h"
#import "OFX509TBSCertificate.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

void *_OFX509CertificatePrivateKeyKey = &_OFX509CertificatePrivateKeyKey;

@implementation OFX509Certificate
@synthesize TBSCertificate = _TBSCertificate;
@synthesize signatureAlgorithm = _signatureAlgorithm;
@synthesize signatureValue = _signatureValue;

+ (bool)supportsPEMFiles
{
	return true;
}

+ (bool)supportsPKCS12Files
{
	return false;
}

static void
parseCertificates(OFString *section, OFData *data, void *ctx)
{
	if (![section isEqual: @"CERTIFICATE"])
		return;

	OFASN1Sequence *sequence = data.valueByParsingDER;
	if (![sequence isKindOfClass: [OFASN1Sequence class]])
		@throw [OFInvalidFormatException exception];

	[(OFMutableArray *)ctx addObject:
	    [sequence parsedAs: [OFX509Certificate class]]];
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)IRI
{
	OFMutableArray *certificateChain = [OFMutableArray array];

	void *pool = objc_autoreleasePoolPush();
	OFParsePEM([OFIRIHandler openItemAtIRI: IRI mode: @"r"],
	    parseCertificates, certificateChain);
	objc_autoreleasePoolPop(pool);

	return certificateChain;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	OFArray *certificateChain =
	    [self certificateChainFromPEMFileAtIRI: certificatesIRI];

	if (privateKeyIRI != nil && certificateChain.count > 0) {
		void *pool = objc_autoreleasePoolPush();

		OFPKCS8PrivateKey *privateKey = [OFPKCS8PrivateKey
		    privateKeyFromPEMFileAtIRI: privateKeyIRI];
		objc_setAssociatedObject(certificateChain.firstObject,
		    _OFX509CertificatePrivateKeyKey, privateKey,
		    OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		objc_autoreleasePoolPop(pool);
	}

	return certificateChain;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (OFString *)passphrase
{
	OF_UNRECOGNIZED_SELECTOR
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

		if (components.count != 3)
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_TBSCertificate = objc_retain(
		    [value parsedAs: [OFX509TBSCertificate class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_signatureAlgorithm = objc_retain(
		    [value parsedAs: [OFX509AlgorithmIdentifier class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1BitString class]])
			@throw [OFInvalidFormatException exception];
		_signatureValue = objc_retain(value);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_TBSCertificate);
	objc_release(_signatureAlgorithm);
	objc_release(_signatureValue);

	[super dealloc];
}

- (OFString *)description
{
	OFString *TBSCertificate = [_TBSCertificate.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *signatureAlgorithm = [_signatureAlgorithm.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *signatureValue = [_signatureValue.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %@\n"
	    @"\tTag number = %@\n"
	    @"\tTBSCertificate = %@\n"
	    @"\tSignature algorithm = %@\n"
	    @"\tSignature value = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), TBSCertificate,
	    signatureAlgorithm, signatureValue];
}
@end
