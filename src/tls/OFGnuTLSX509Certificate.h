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

#import "OFX509Certificate.h"

#include <gnutls/x509.h>

OF_ASSUME_NONNULL_BEGIN

OF_SUBCLASSING_RESTRICTED
@interface OFGnuTLSX509Certificate: OFX509Certificate
{
	gnutls_x509_crt_t _certificate;
	gnutls_x509_privkey_t _Nullable _privateKey;
}

@property (readonly, nonatomic) gnutls_x509_crt_t of_certificate;
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    gnutls_x509_privkey_t of_privateKey;

- (instancetype)
    of_initWithCertificate: (gnutls_x509_crt_t)certificate
		privateKey: (nullable gnutls_x509_privkey_t)privateKey;
@end

OF_ASSUME_NONNULL_END
