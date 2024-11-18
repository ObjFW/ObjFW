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

#import "OFGnuTLSX509CertificatePrivateKey.h"
#import "OFData.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFGnuTLSX509CertificatePrivateKey
@synthesize of_gnuTLSPrivateKey = _privateKey;

+ (void)load
{
	if (OFX509CertificatePrivateKeyImplementation == Nil)
		OFX509CertificatePrivateKeyImplementation = self;
}

+ (instancetype)privateKeyFromIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	gnutls_datum_t datum;
	gnutls_x509_privkey_t key;
	OFGnuTLSX509CertificatePrivateKey *privateKey;

	if (data.count * data.itemSize > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	datum.data = (unsigned char *)data.items;
	datum.size = (unsigned int)(data.count * data.itemSize);

	if (gnutls_x509_privkey_init(&key) != GNUTLS_E_SUCCESS)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	if (gnutls_x509_privkey_import(key, &datum,
	    GNUTLS_X509_FMT_PEM) != GNUTLS_E_SUCCESS) {
		gnutls_x509_privkey_deinit(key);
		@throw [OFInvalidFormatException exception];
	}

	@try {
		privateKey = [[self alloc] of_initWithGnuTLSPrivateKey: key];
	} @catch (id e) {
		gnutls_x509_privkey_deinit(key);
		@throw e;
	}

	objc_autoreleasePoolPop(pool);

	return [privateKey autorelease];
}

- (instancetype)of_initWithGnuTLSPrivateKey: (gnutls_x509_privkey_t)privateKey
{
	self = [super init];

	_privateKey = privateKey;

	return self;
}

- (void)dealloc
{
	gnutls_x509_privkey_deinit(_privateKey);

	[super dealloc];
}
@end
