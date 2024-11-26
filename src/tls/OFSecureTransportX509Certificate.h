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

#ifndef OF_IOS
# include <Security/SecCertificate.h>

OF_ASSUME_NONNULL_BEGIN

@class OFSecureTransportKeychain;

OF_SUBCLASSING_RESTRICTED
@interface OFSecureTransportX509Certificate: OFX509Certificate
{
	SecCertificateRef _certificate;
	SecKeychainItemRef _Nullable _privateKey;
	OFSecureTransportKeychain *_keychain;
}

@property (readonly, nonatomic) SecCertificateRef of_certificate;
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    SecKeychainItemRef of_privateKey;

- (instancetype)of_initWithCertificate: (SecCertificateRef)certificate
			    privateKey: (nullable SecKeychainItemRef)privateKey
			      keychain: (OFSecureTransportKeychain *)keychain;
@end

OF_ASSUME_NONNULL_END
#endif
