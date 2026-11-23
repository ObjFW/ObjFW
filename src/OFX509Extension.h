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
 * @class OFX509Extension OFX509Extension.h ObjFW/ObjFW.h
 *
 * @brief An X.509 Extension.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509Extension: OFASN1Sequence
{
	OFASN1ObjectIdentifier *_extensionID;
	bool _critical;
	OFData *_extensionValueData;
	OF_KINDOF(OFASN1Value *) _extensionValue;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFASN1ObjectIdentifier *keyUsageOID;
@property (class, readonly, nonatomic)
    OFASN1ObjectIdentifier *basicConstraintsOID;
#endif

/**
 * @brief The extnID of the Extension.
 */
@property (readonly, nonatomic) OFASN1ObjectIdentifier *extensionID;

/**
 * @brief Whether the Extension is critical.
 */
@property (readonly, nonatomic, getter=isCritical) bool critical;

/**
 * @brief The extnValue of the Extension for known extensions, otherwise `nil`.
 *
 * @note While the standard specifies the value always needs to be DER-encoded,
 *	 in practice, there are extensions that don't encode the Extension
 *	 value in DER (e.g. Yubico), in violation of the standard. Therefore,
 *	 only known Extensions are parsed. To get the raw Extension value, use
 *	 @ref extensionValueData instead.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OF_KINDOF(OFASN1Value *) extensionValue;

/**
 * @brief The extnValue of the Extension as data.
 */
@property (readonly, nonatomic) OFData *extensionValueData;

/**
 * @brief The OID for the Key Usage Extension.
 */
+ (OFASN1ObjectIdentifier *)keyUsageOID;

/**
 * @brief The OID for the Basic Constraints Extension.
 */
+ (OFASN1ObjectIdentifier *)basicConstraintsOID;
@end

OF_ASSUME_NONNULL_END
