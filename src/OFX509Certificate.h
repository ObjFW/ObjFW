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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFASN1Integer;
@class OFASN1Sequence;
@class OFASN1Value;
@class OFIRI;
@class OFPKCS8PrivateKey;

/**
 * @class OFX509Certificate OFX509Certificate.h ObjFW/ObjFW.h
 *
 * @brief An X.509 certificate, optionally with an associated private key.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509Certificate: OFObject
{
	OFASN1Sequence *_ASN1Value;
	OFPKCS8PrivateKey *_Nullable _associatedPrivateKey;
	int _version;
	OFASN1Integer *_serialNumber;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) bool supportsPEMFiles;
@property (class, readonly, nonatomic) bool supportsPKCS12Files;
#endif

/**
 * @brief The certificate as an @ref OFASN1Value.
 */
@property (readonly, nonatomic) OF_KINDOF(OFASN1Value *) ASN1Value;

/**
 * @brief The private key for the certificate as an @ref OFASN1Value.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFPKCS8PrivateKey *associatedPrivateKey;

/**
 * @brief Returns whether creating a certificate chain from PEM files is
 *	  supported.
 *
 * @return Whether creating a certificate chain from PEM files is supported
 */
+ (bool)supportsPEMFiles;

/**
 * @brief Returns whether creating a certificate chain from a PKCS #12 file is
 *	  supported.
 *
 * @deprecated PKCS #12 is no longer supported, so this always returns `false`.
 *
 * @return Whether creating a certificate chain from a PKCS #12 file is
 *	   supported
 */
+ (bool)supportsPKCS12Files
    OF_DEPRECATED(ObjFW, 1, 6, "PKCS #12 is no longer supported");

/**
 * @brief The version of the certificate.
 */
@property (readonly, nonatomic) int version;

/**
 * @brief The serial number of the certificate.
 */
@property (readonly, nonatomic) OFASN1Integer *serialNumber;

/**
 * @brief Returns the certificate chain from the PEM file at the specified IRI.
 *
 * @param certificatesIRI The IRI to the PEM file with the certificate chain
 * @param privateKeyIRI An optional IRI to the PEM file with the private key or
 *			`nil`
 * @return An array of @ref OFX509Certificate
 * @throw OFOpenItemFailedException Opening the item failed
 * @throw OFUnsupportedProtocolException The specified IRI is not supported
 * @throw OFReadFailedException Reading the item failed
 * @throw OFInvalidFormatException The format of the item is invalid
 */
+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (nullable OFIRI *)privateKeyIRI;

/**
 * @brief Returns the certificate chain from the PKCS #12 file at the specified
 *	  IRI.
 *
 * @deprecated PKCS #12 is no longer supported, so this always throws @ref
 *	       OFNotImplementedException.
 *
 * @param IRI The IRI to the PKCS #12 file with the certificate chain
 * @param passphrase The passphrase for the PKCS #12 file
 * @return An array of @ref OFX509Certificate
 * @throw OFOpenItemFailedException Opening the item failed
 * @throw OFUnsupportedProtocolException The specified IRI is not supported
 * @throw OFReadFailedException Reading the item failed
 * @throw OFInvalidFormatException The format of the item is invalid
 */
+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (nullable OFString *)passphrase
    OF_DEPRECATED(ObjFW, 1, 6, "PKCS #12 is no longer supported");

/**
 * @brief Creates a new @ref OFX509Certificate with the specified ASN.1 value.
 *
 * @param ASN1Value The ASN.1 value
 * @return An new @ref OFX509Certificate
 * @throw OFInvalidFormatException The specified format is not a properly
 *				   formatted X.509 certificate
 */
+ (instancetype)certificateWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value;

/**
 * @brief Creates a new @ref OFX509Certificate with the specified ASN.1 value.
 *
 * @param ASN1Value The ASN.1 value
 * @param associatedPrivateKey The associated private key for the certificate
 * @return An new @ref OFX509Certificate
 * @throw OFInvalidFormatException The specified format is not a properly
 *				   formatted X.509 certificate
 */
+ (instancetype)certificateWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
		    associatedPrivateKey: (nullable OFPKCS8PrivateKey *)
					      associatedPrivateKey;

/**
 * @brief Initializes an already allocated @ref OFX509Certificate with the
 *	  specified ASN.1 value.
 *
 * @param ASN1Value The ASN.1 value
 * @return An initialized @ref OFX509Certificate
 * @throw OFInvalidFormatException The specified format is not a properly
 *				   formatted X.509 certificate
 */
- (instancetype)initWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value;

/**
 * @brief Initializes an already allocated @ref OFX509Certificate with the
 *	  specified ASN.1 value.
 *
 * @param ASN1Value The ASN.1 value
 * @param associatedPrivateKey The private key for the certificate
 * @return An initialized @ref OFX509Certificate
 * @throw OFInvalidFormatException The specified format is not a properly
 *				   formatted X.509 certificate
 */
- (instancetype)initWithASN1Value: (OF_KINDOF(OFASN1Value *))ASN1Value
	     associatedPrivateKey: (nullable OFPKCS8PrivateKey *)
				       associatedPrivateKey
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
