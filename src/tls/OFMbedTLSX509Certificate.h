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

#import "OFX509Certificate.h"

#include <mbedtls/x509_crt.h>

OF_ASSUME_NONNULL_BEGIN

/*
 * While MbedTLS does have a X.509 certificate type, it is a linked list that
 * represents a chain. There is no way to remove a certificate from the chain
 * and store it separately. Therefore, it is necessary to store the entire
 * chain and have every wrapped certificate reference it.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMbedTLSX509CertificateChain: OFObject
{
	mbedtls_x509_crt _certificate;
}

@property (readonly, nonatomic) mbedtls_x509_crt *certificate;
@end

OF_SUBCLASSING_RESTRICTED
@interface OFMbedTLSX509Certificate: OFX509Certificate
{
	mbedtls_x509_crt *_certificate;
	OFMbedTLSX509CertificateChain *_chain;
}

@property (readonly, nonatomic) mbedtls_x509_crt *of_mbedTLSCertificate;
@property (readonly, retain, nonatomic)
    OFMbedTLSX509CertificateChain *of_mbedTLSChain;

- (instancetype)
    of_initWithMbedTLSCertificate: (mbedtls_x509_crt *)certificate
			    chain: (OFMbedTLSX509CertificateChain *)chain;
@end

OF_ASSUME_NONNULL_END