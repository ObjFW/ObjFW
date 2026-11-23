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

#import "OFASN1BitString.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFX509KeyUsage OFX509KeyUsage.h ObjFW/ObjFW.h
 *
 * @brief An X.509 Key Usage extension.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509KeyUsage: OFASN1BitString
{
	uint16_t _keyUsage;
}

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `digitalSignature`.
 */
@property (readonly, nonatomic) bool digitalSignature;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `nonRepudiation`.
 */
@property (readonly, nonatomic) bool nonRepudiation;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `keyEncipherment`.
 */
@property (readonly, nonatomic) bool keyEncipherment;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `dataEncipherment`.
 */
@property (readonly, nonatomic) bool dataEncipherment;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `keyAgreement`.
 */
@property (readonly, nonatomic) bool keyAgreement;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `keyCertSign`.
 */
@property (readonly, nonatomic) bool keyCertSign;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `cRLSign`.
 */
@property (readonly, nonatomic) bool CRLSign;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `encipherOnly`.
 */
@property (readonly, nonatomic) bool encipherOnly;

/**
 * @brief Whether the key contained in the certificate can be used for
 *	  `decipherOnly`.
 */
@property (readonly, nonatomic) bool decipherOnly;
@end

OF_ASSUME_NONNULL_END
