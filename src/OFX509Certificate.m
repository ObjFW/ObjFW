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

void *_OFX509CertificatePrivateKeyKey = &_OFX509CertificatePrivateKeyKey;

@implementation OFX509Certificate
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
@end
