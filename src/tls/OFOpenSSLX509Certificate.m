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

#import "OFOpenSSLX509Certificate.h"
#import "OFArray.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

static EVP_PKEY *
privateKeyFromFile(OFIRI *IRI)
{
	void *pool;
	OFData *data;
	BIO *bio;
	EVP_PKEY *key;

	if (IRI == nil)
		return NULL;

	pool = objc_autoreleasePoolPush();
	data = [OFData dataWithContentsOfIRI: IRI];

	if (data.count * data.itemSize > INT_MAX)
		@throw [OFOutOfRangeException exception];

	bio = BIO_new_mem_buf(data.items, (int)(data.count * data.itemSize));
	if (bio == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: data.count * data.itemSize];

	key = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);
	if (key == NULL) {
		BIO_free(bio);
		@throw [OFInvalidFormatException exception];
	}

	BIO_free(bio);
	objc_autoreleasePoolPop(pool);

	return key;
}

@implementation OFOpenSSLX509Certificate
@synthesize of_certificate = _certificate, of_privateKey = _privateKey;

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: certificatesIRI];
	BIO *bio;

	if (data.count * data.itemSize > INT_MAX)
		@throw [OFOutOfRangeException exception];

	bio = BIO_new_mem_buf(data.items, (int)(data.count * data.itemSize));
	if (bio == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: data.count * data.itemSize];

	@try {
		bool first = true;

		for (;;) {
			OFOpenSSLX509Certificate *certificate;
			X509 *cert = X509_new();
			EVP_PKEY *key = NULL;

			if (cert == NULL)
				@throw [OFOutOfMemoryException exception];

			if (PEM_read_bio_X509(bio, &cert, NULL, NULL) == NULL) {
				X509_free(cert);
				break;
			}

			@try {
				if (first) {
					key = privateKeyFromFile(privateKeyIRI);
					certificate = [[self alloc]
					    of_initWithCertificate: cert
							privateKey: key];
					first = false;
				} else
					certificate = [[self alloc]
					    of_initWithCertificate: cert
							privateKey: NULL];
			} @catch (id e) {
				X509_free(cert);

				if (key != NULL)
					EVP_PKEY_free(key);

				@throw e;
			}

			@try {
				[chain addObject: certificate];
			} @finally {
				[certificate release];
			}
		}
	} @finally {
		BIO_free(bio);
	}

	[chain makeImmutable];

	objc_autoreleasePoolPop(pool);

	return chain;
}

- (instancetype)of_initWithCertificate: (X509 *)certificate
			    privateKey: (EVP_PKEY *)privateKey
{
	self = [super init];

	_certificate = certificate;
	_privateKey = privateKey;

	return self;
}

- (void)dealloc
{
	X509_free(_certificate);

	if (_privateKey != NULL)
		EVP_PKEY_free(_privateKey);

	[super dealloc];
}
@end
