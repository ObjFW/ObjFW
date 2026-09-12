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

#import "OFOpenSSLX509Name.h"
#import "OFString.h"
#import "OFX509Name+Private.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

@implementation OFOpenSSLX509Name
- (instancetype)of_initWithName: (const X509_NAME *)name
		    certificate: (X509 *)certificate
{
	self = [super of_init];

	@try {
		_name = name;

		if (X509_up_ref(certificate) != 1)
			@throw [OFOutOfRangeException exception];

		_certificate = certificate;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	X509_free(_certificate);

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	if (![object isKindOfClass: [OFOpenSSLX509Name class]])
		return false;

	OFOpenSSLX509Name *name = (OFOpenSSLX509Name *)object;
	return (X509_NAME_cmp(_name, name->_name) == 0);
}

- (unsigned long)hash
{
	/* Cast needed to make LibreSSL happy */
	return X509_NAME_hash((X509_NAME *)_name);
}

- (OFString *)description
{
	BIO *bio = BIO_new(BIO_s_mem());
	if (bio == NULL)
		@throw [OFOutOfMemoryException exception];

	@try {
		if (X509_NAME_print_ex(bio, _name, 0, XN_FLAG_RFC2253) < 0)
			@throw [OFInvalidFormatException exception];

		BUF_MEM *mem;
		BIO_get_mem_ptr(bio, &mem);

		return [OFString stringWithUTF8String: mem->data
					       length: mem->length];
	} @finally {
		BIO_free(bio);
	}
}
@end
