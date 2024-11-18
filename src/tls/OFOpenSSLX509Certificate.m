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

@implementation OFOpenSSLX509Certificate
@synthesize of_openSSLCertificate = _certificate;

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)IRI
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	BIO *bio;

	if (data.count * data.itemSize > INT_MAX)
		@throw [OFOutOfRangeException exception];

	bio = BIO_new_mem_buf(data.items, (int)(data.count * data.itemSize));
	if (bio == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: data.count * data.itemSize];

	@try {
		for (;;) {
			OFOpenSSLX509Certificate *certificate;
			X509 *cert = X509_new();

			if (cert == NULL)
				@throw [OFOutOfMemoryException exception];

			if (PEM_read_bio_X509(bio, &cert, NULL, NULL) == NULL) {
				X509_free(cert);
				break;
			}

			@try {
				certificate = [[self alloc]
				    of_initWithOpenSSLCertificate: cert];
			} @catch (id e) {
				X509_free(cert);
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

- (instancetype)of_initWithOpenSSLCertificate: (X509 *)certificate
{
	self = [super init];

	_certificate = certificate;

	return self;
}

- (void)dealloc
{
	X509_free(_certificate);

	[super dealloc];
}
@end
