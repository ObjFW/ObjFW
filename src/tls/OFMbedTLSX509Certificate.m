/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFMbedTLSX509Certificate.h"
#import "OFArray.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"

@implementation OFMbedTLSX509CertificateChain
- (instancetype)init
{
	self = [super init];

	mbedtls_x509_crt_init(&_certificate);
	mbedtls_pk_init(&_privateKey);

	return self;
}

- (void)dealloc
{
	mbedtls_x509_crt_free(&_certificate);
	mbedtls_pk_free(&_privateKey);

	[super dealloc];
}

- (mbedtls_x509_crt *)certificate
{
	return &_certificate;
}

- (mbedtls_pk_context *)privateKey
{
	return &_privateKey;
}
@end

@implementation OFMbedTLSX509Certificate
@synthesize of_certificate = _certificate, of_chain = _chain;

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

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
	OFMutableArray *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data =
	    [OFMutableData dataWithContentsOfIRI: certificatesIRI];
	OFMbedTLSX509CertificateChain *chain =
	    [[[OFMbedTLSX509CertificateChain alloc] init] autorelease];

	/* Terminating zero byte required for PEM. */
	[data addItem: ""];

	if (mbedtls_x509_crt_parse(chain.certificate, data.items,
	    data.count * data.itemSize) != 0)
		@throw [OFInvalidFormatException exception];

	if (privateKeyIRI != nil) {
		data = [OFMutableData dataWithContentsOfIRI: privateKeyIRI];

		/* Terminating zero byte required for PEM. */
		[data addItem: ""];

		if (mbedtls_pk_parse_key(chain.privateKey,
		    data.items, data.count * data.itemSize, NULL, 0) != 0)
			@throw [OFInvalidFormatException exception];
	}

	for (mbedtls_x509_crt *iter = chain.certificate; iter != NULL;
	    iter = iter->next)
		[ret addObject:
		    [[[self alloc] of_initWithCertificate: iter
						    chain: chain] autorelease]];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (instancetype)of_initWithCertificate: (mbedtls_x509_crt *)certificate
				 chain: (OFMbedTLSX509CertificateChain *)chain
{
	self = [super init];

	_certificate = certificate;
	_chain = [chain retain];

	return self;
}

- (void)dealloc
{
	[_chain release];

	[super dealloc];
}
@end
