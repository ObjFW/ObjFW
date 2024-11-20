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

#import "OFMbedTLSX509CertificatePrivateKey.h"
#import "OFData.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"

@implementation OFMbedTLSX509CertificatePrivateKey
+ (void)load
{
	if (OFX509CertificatePrivateKeyImplementation == Nil)
		OFX509CertificatePrivateKeyImplementation = self;
}

+ (instancetype)privateKeyFromPEMFileAtIRI: (OFIRI *)IRI
{
	OFMbedTLSX509CertificatePrivateKey *privateKey =
	    [[[self alloc] init] autorelease];
	void *pool = objc_autoreleasePoolPush();
	OFMutableData *data = [OFMutableData dataWithContentsOfIRI: IRI];

	/* Terminating zero byte required for PEM. */
	[data addItem: ""];

	if (mbedtls_pk_parse_key(privateKey.of_mbedTLSPrivateKey,
	    data.items, data.count * data.itemSize, NULL, 0) != 0)
		@throw [OFInvalidFormatException exception];

	objc_autoreleasePoolPop(pool);

	return privateKey;
}

- (mbedtls_pk_context *)of_mbedTLSPrivateKey
{
	return &_privateKey;
}

- (instancetype)init
{
	self = [super init];

	mbedtls_pk_init(&_privateKey);

	return self;
}

- (void)dealloc
{
	mbedtls_pk_free(&_privateKey);

	[super dealloc];
}
@end
