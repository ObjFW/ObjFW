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

#import "OFGnuTLSX509Certificate.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFString.h"

#include <gnutls/pkcs12.h>

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

static gnutls_x509_privkey_t
privateKeyFromFile(OFIRI *IRI)
{
	void *pool;
	OFData *data;
	gnutls_datum_t datum;
	gnutls_x509_privkey_t key;

	if (IRI == nil)
		return NULL;

	pool = objc_autoreleasePoolPush();
	data = [OFData dataWithContentsOfIRI: IRI];

	if (data.count * data.itemSize > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	datum.data = (unsigned char *)data.items;
	datum.size = (unsigned int)(data.count * data.itemSize);

	if (gnutls_x509_privkey_init(&key) != GNUTLS_E_SUCCESS)
		@throw [OFOutOfMemoryException exception];

	if (gnutls_x509_privkey_import(key, &datum,
	    GNUTLS_X509_FMT_PEM) != GNUTLS_E_SUCCESS) {
		gnutls_x509_privkey_deinit(key);
		@throw [OFInvalidFormatException exception];
	}

	objc_autoreleasePoolPop(pool);

	return key;
}

@implementation OFGnuTLSX509Certificate
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
	gnutls_datum_t datum;
	gnutls_x509_crt_t *certs;
	unsigned int i, size;

	if (data.count * data.itemSize > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	datum.data = (unsigned char *)data.items;
	datum.size = (unsigned int)(data.count * data.itemSize);

	if (gnutls_x509_crt_list_import2(&certs, &size, &datum,
	    GNUTLS_X509_FMT_PEM, 0) != GNUTLS_E_SUCCESS)
		@throw [OFInvalidFormatException exception];

	for (i = 0; i < size; i++) {
		gnutls_x509_privkey_t key = NULL;
		OFGnuTLSX509Certificate *certificate;

		@try {
			if (i == 0)
				key = privateKeyFromFile(privateKeyIRI);

			certificate = [[self alloc]
			    of_initWithCertificate: certs[i]
					privateKey: key];
		} @catch (id e) {
			for (; i < size; i++)
				gnutls_x509_crt_deinit(certs[i]);

			gnutls_free(certs);

			if (key != NULL)
				gnutls_x509_privkey_deinit(key);

			@throw e;
		}

		@try {
			[chain addObject: certificate];
		} @catch (id e) {
			gnutls_free(certs);
			@throw e;
		} @finally {
			[certificate release];
		}
	}

	gnutls_free(certs);

	[chain makeImmutable];

	objc_autoreleasePoolPop(pool);

	return chain;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (OFString *)passphrase
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	gnutls_x509_crt_t *certs = NULL;
	gnutls_x509_privkey_t key = NULL;
	unsigned int i = 0, certsCount = 0;
	gnutls_pkcs12_t p12;

	if (gnutls_pkcs12_init(&p12) != 0)
		@throw [OFOutOfMemoryException exception];

	@try {
		gnutls_datum_t datum;

		if (data.count * data.itemSize > UINT_MAX)
			@throw [OFOutOfRangeException exception];

		datum.data = (unsigned char *)data.items;
		datum.size = (unsigned int)(data.count * data.itemSize);

		if (gnutls_pkcs12_import(p12, &datum,
		    GNUTLS_X509_FMT_DER, 0) != 0)
			@throw [OFInvalidFormatException exception];

		if (passphrase != nil)
			if (gnutls_pkcs12_verify_mac(p12,
			    passphrase.UTF8String) != 0)
				@throw [OFInvalidFormatException exception];

		if (gnutls_pkcs12_simple_parse(p12, passphrase.UTF8String,
		    &key, &certs, &certsCount, NULL, NULL, NULL, 0) != 0)
			@throw [OFInvalidFormatException exception];

		for (i = 0; i < certsCount; i++) {
			[chain addObject: [[[OFGnuTLSX509Certificate alloc]
			    of_initWithCertificate: certs[i]
					privateKey: key] autorelease]];
			key = NULL;
		}
	} @finally {
		gnutls_pkcs12_deinit(p12);

		if (certs != NULL) {
			for (; i < certsCount; i++)
				gnutls_x509_crt_deinit(certs[i]);

			gnutls_free(certs);
		}

		if (key != NULL)
			gnutls_x509_privkey_deinit(key);
	}

	[chain makeImmutable];

	objc_autoreleasePoolPop(pool);

	return chain;
}

- (instancetype)of_initWithCertificate: (gnutls_x509_crt_t)certificate
			    privateKey: (gnutls_x509_privkey_t)privateKey
{
	self = [super init];

	_certificate = certificate;
	_privateKey = privateKey;

	return self;
}

- (void)dealloc
{
	gnutls_x509_crt_deinit(_certificate);

	if (_privateKey != NULL)
		gnutls_x509_privkey_deinit(_privateKey);

	[super dealloc];
}
@end
