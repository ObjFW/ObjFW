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

/** @file */

@class OFASN1BitString;
@class OFASN1Integer;
@class OFArray OF_GENERIC(ObjectType);
@class OFX509AlgorithmIdentifier;
@class OFX509Extension;
@class OFX509Name;
@class OFX509SubjectPublicKeyInfo;
@class OFX509Validity;

/**
 * @brief An X.509 CertificateSerialNumber.
 */
typedef OFASN1Integer OFX509CertificateSerialNumber;

/**
 * @brief An X.509 UniqueIdentifier.
 */
typedef OFASN1BitString OFX509UniqueIdentifier;

/**
 * @class OFX509TBSCertificate OFX509TBSCertificate.h ObjFW/ObjFW.h
 *
 * @brief An X.509 TBSCertificate.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509TBSCertificate: OFASN1Sequence
{
	int _version;
	OFX509CertificateSerialNumber *_serialNumber;
	OFX509AlgorithmIdentifier *_signature;
	OFX509Name *_issuer;
	OFX509Validity *_validity;
	OFX509Name *_subject;
	OFX509SubjectPublicKeyInfo *_subjectPublicKeyInfo;
	OFX509UniqueIdentifier *_Nullable _issuerUniqueID;
	OFX509UniqueIdentifier *_Nullable _subjectUniqueID;
	OFArray OF_GENERIC(OFX509Extension *) *_Nullable _extensions;
}

/**
 * @brief The version of the certificate.
 */
@property (readonly, nonatomic) int version;

/**
 * @brief The serial number of the certificate.
 */
@property (readonly, retain, nonatomic)
    OFX509CertificateSerialNumber *serialNumber;

/**
 * @brief The algorithm used by the CA to sign the certificate.
 */
@property (readonly, retain, nonatomic) OFX509AlgorithmIdentifier *signature;

/**
 * @brief The entity that has signed and issued the certificate.
 */
@property (readonly, retain, nonatomic) OFX509Name *issuer;

/**
 * @brief The validity period of the certificate.
 */
@property (readonly, retain, nonatomic) OFX509Validity *validity;

/**
 * @brief The entity associated with the public key stored in the
 *	  @ref subjectPublicKeyInfo field.
 */
@property (readonly, retain, nonatomic) OFX509Name *subject;

/**
 * @brief The public key and algorithm of the key.
 */
@property (readonly, retain, nonatomic)
    OFX509SubjectPublicKeyInfo *subjectPublicKeyInfo;

/**
 * @brief The unique identifier for the issuer.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFX509UniqueIdentifier *issuerUniqueID;

/**
 * @brief The unique identifier for the entity associated with the public key
 *	  stored in the @ref subjectPublicKeyInfo field.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFX509UniqueIdentifier *subjectUniqueID;

/**
 * @brief One or more optional certificate extensions.
 */
@property OF_NULLABLE_PROPERTY (readonly, retain, nonatomic)
    OFArray OF_GENERIC(OFX509Extension *) *extensions;
@end

OF_ASSUME_NONNULL_END
