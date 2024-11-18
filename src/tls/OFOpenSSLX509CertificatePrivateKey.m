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

#import "OFOpenSSLX509CertificatePrivateKey.h"
#import "OFData.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

@implementation OFOpenSSLX509CertificatePrivateKey
@synthesize of_openSSLPrivateKey = _privateKey;

+ (void)load
{
	if (OFX509CertificatePrivateKeyImplementation == Nil)
		OFX509CertificatePrivateKeyImplementation = self;
}

+ (instancetype)privateKeyFromPEMFileAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	BIO *bio;
	OFOpenSSLX509CertificatePrivateKey *privateKey;

	if (data.count * data.itemSize > INT_MAX)
		@throw [OFOutOfRangeException exception];

	bio = BIO_new_mem_buf(data.items, (int)(data.count * data.itemSize));
	if (bio == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: data.count * data.itemSize];

	@try {
		EVP_PKEY *key = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);

		if (key == NULL)
			@throw [OFInvalidFormatException exception];

		@try {
			privateKey = [[self alloc]
			    of_initWithOpenSSLPrivateKey: key];
		} @catch (id e) {
			EVP_PKEY_free(key);
			@throw e;
		}
	} @finally {
		BIO_free(bio);
	}

	objc_autoreleasePoolPop(pool);

	return [privateKey autorelease];
}

- (instancetype)of_initWithOpenSSLPrivateKey: (EVP_PKEY *)privateKey
{
	self = [super init];

	_privateKey = privateKey;

	return self;
}

- (void)dealloc
{
	EVP_PKEY_free(_privateKey);

	[super dealloc];
}
@end
