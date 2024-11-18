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

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

@implementation OFGnuTLSX509Certificate
@synthesize of_gnuTLSCertificate = _certificate;

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromIRI: (OFIRI *)IRI
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
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
		OFGnuTLSX509Certificate *certificate;

		@try {
			certificate = [[self alloc]
			    of_initWithGnuTLSCertificate: certs[i]];
		} @catch (id e) {
			gnutls_x509_crt_deinit(certs[i]);
			gnutls_free(certs);
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

	objc_autoreleasePoolPop(pool);

	return chain;
}

- (instancetype)of_initWithGnuTLSCertificate: (gnutls_x509_crt_t)certificate
{
	self = [super init];

	_certificate = certificate;

	return self;
}

- (void)dealloc
{
	gnutls_x509_crt_deinit(_certificate);

	[super dealloc];
}
@end
