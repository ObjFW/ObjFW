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

#include <Security/SecCertificate.h>

OF_ASSUME_NONNULL_BEGIN

@class OFSecureTransportKeychain;

OF_SUBCLASSING_RESTRICTED
@interface OFSecureTransportX509Certificate: OFX509Certificate
{
	SecCertificateRef _certificate;
#ifndef OF_IOS
	SecKeychainItemRef _Nullable _privateKey;
	OFSecureTransportKeychain *_keychain;
#endif
}

@property (readonly, nonatomic) SecCertificateRef of_certificate;
#ifndef OF_IOS
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    SecKeychainItemRef of_privateKey;
#endif

#ifndef OF_IOS
- (instancetype)of_initWithCertificate: (SecCertificateRef)certificate
			    privateKey: (nullable SecKeychainItemRef)privateKey
			      keychain: (OFSecureTransportKeychain *)keychain;
#else
- (instancetype)of_initWithCertificate: (SecCertificateRef)certificate;
#endif
@end

OF_ASSUME_NONNULL_END
