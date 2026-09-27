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

#import "OFASN1Sequence.h"

OF_ASSUME_NONNULL_BEGIN

@class OFASN1ObjectIdentifier;

/**
 * @class OFX509AlgorithmIdentifier OFX509AlgorithmIdentifier.h ObjFW/ObjFW.h
 *
 * @brief An X.509 AlgorithmIdentifier.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509AlgorithmIdentifier: OFASN1Sequence
{
	OFASN1ObjectIdentifier *_algorithm;
	OFASN1Value *_Nullable _parameters;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *SHA256WithRSAEncryptionOID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *SHA384WithRSAEncryptionOID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *SHA512WithRSAEncryptionOID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *SHA224WithRSAEncryptionOID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *ECDSAWithSHA224OID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *ECDSAWithSHA256OID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *ECDSAWithSHA384OID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *ECDSAWithSHA512OID;
@property (class, readonly, nonatomic) OFASN1ObjectIdentifier *Ed25519OID;
@property (class, readonly, nonatomic) OFASN1ObjectIdentifier *Ed448OID;
#endif

/**
 * @brief The algorithm of the X.509 AlgorithmIdentifier.
 */
@property (readonly, nonatomic) OFASN1ObjectIdentifier *algorithm;

/**
 * @brief The optional, algorithm-specific parameters of the X.509
 *	  AlgorithmIdentifier.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OF_KINDOF(OFASN1Value *) parameters;

/**
 * @brief Returns the OID for SHA-256 with RSA encryption.
 *
 * @return The OID for SHA-256 with RSA encryption.
 */
+ (OFASN1ObjectIdentifier *)SHA256WithRSAEncryptionOID;

/**
 * @brief Returns the OID for SHA-384 with RSA encryption.
 *
 * @return The OID for SHA-384 with RSA encryption.
 */
+ (OFASN1ObjectIdentifier *)SHA384WithRSAEncryptionOID;

/**
 * @brief Returns the OID for SHA-512 with RSA encryption.
 *
 * @return The OID for SHA-512 with RSA encryption.
 */
+ (OFASN1ObjectIdentifier *)SHA512WithRSAEncryptionOID;

/**
 * @brief Returns the OID for SHA-224 with RSA encryption.
 *
 * @return The OID for SHA-224 with RSA encryption.
 */
+ (OFASN1ObjectIdentifier *)SHA224WithRSAEncryptionOID;

/**
 * @brief Returns the OID for ECDSA with SHA-224
 *
 * @return The OID for ECDSA with SHA-224
 */
+ (OFASN1ObjectIdentifier *)ECDSAWithSHA224OID;

/**
 * @brief Returns the OID for ECDSA with SHA-256
 *
 * @return The OID for ECDSA with SHA-256
 */
+ (OFASN1ObjectIdentifier *)ECDSAWithSHA256OID;

/**
 * @brief Returns the OID for ECDSA with SHA-384
 *
 * @return The OID for ECDSA with SHA-384
 */
+ (OFASN1ObjectIdentifier *)ECDSAWithSHA384OID;

/**
 * @brief Returns the OID for ECDSA with SHA-512
 *
 * @return The OID for ECDSA with SHA-512
 */
+ (OFASN1ObjectIdentifier *)ECDSAWithSHA512OID;

/**
 * @brief Returns the OID for Ed25519
 *
 * @return The OID for Ed25519
 */
+ (OFASN1ObjectIdentifier *)Ed25519OID;

/**
 * @brief Returns the OID for Ed448
 *
 * @return The OID for Ed448
 */
+ (OFASN1ObjectIdentifier *)Ed448OID;
@end

OF_ASSUME_NONNULL_END
