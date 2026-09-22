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
	OFData *_extensionValue;
}

/**
 * @brief The extnID of the Extension.
 */
@property (readonly, retain, nonatomic) OFASN1ObjectIdentifier *extensionID;

/**
 * @brief Whether the Extension is critical.
 */
@property (readonly, nonatomic, getter=isCritical) bool critical;

/**
 * @brief The extnValue of the Extension.
 */
@property (readonly, retain, nonatomic) OFData *extensionValue;
@end

OF_ASSUME_NONNULL_END
