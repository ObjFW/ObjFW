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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;

/**
 * @class OFX509CertificatePrivateKey \
 *	  OFX509CertificatePrivateKey.h ObjFW/ObjFW.h
 *
 * @brief The private key for an X.509 certificate.
 */
@interface OFX509CertificatePrivateKey: OFObject
{
	OF_RESERVE_IVARS(OFX509Certificate, 4)
}

#ifndef OF_IOS
/**
 * @brief Returns the private key from the PEM file at the specified IRI.
 *
 * @param IRI The IRI to retrieve the private key from
 * @return A private key
 * @throw OFInitializationFailedException Initializing the private key failed
 * @throw OFOpenItemFailedException Opening the item failed
 * @throw OFUnsupportedProtocolException The specified IRI is not supported
 * @throw OFReadFailedException Reading the item failed
 * @throw OFInvalidFormatException The format of the item is invalid
 */
+ (instancetype)privateKeyFromPEMFileAtIRI: (OFIRI *)IRI;
#endif
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The implementation for OFX509CertificatePrivateKey to use.
 *
 * This can be set to a class that is always used for
 * OFX509CertificatePrivateKey. This is useful to either force a specific
 * implementation or to use one that ObjFW does not know about.
 */
extern Class OFX509CertificatePrivateKeyImplementation;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
