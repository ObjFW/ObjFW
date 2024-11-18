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

@class OFArray OF_GENERIC(ObjectType);
@class OFIRI;

/**
 * @class OFX509Certificate OFX509Certificate.h ObjFW/ObjFW.h
 *
 * @brief An X.509 certificate.
 */
@interface OFX509Certificate: OFObject
{
	OF_RESERVE_IVARS(OFX509Certificate, 4)
}

/**
 * @brief Returns the certificate chain from the PEM file at the specified IRI.
 *
 * @param IRI The IRI to the PEM file to retrieve the certificate chain from
 * @return An array of @ref OFX509Certificate
 * @throw OFOpenItemFailedException Opening the item failed
 * @throw OFUnsupportedProtocolException The specified IRI is not supported
 * @throw OFReadFailedException Reading the item failed
 * @throw OFInvalidFormatException The format of the item is invalid
 */
+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)IRI;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The implementation for OFX509Certificate to use.
 *
 * This can be set to a class that is always used for OFX509Certificate. This
 * is useful to either force a specific implementation or to use one that ObjFW
 * does not know about.
 */
extern Class OFX509CertificateImplementation;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
