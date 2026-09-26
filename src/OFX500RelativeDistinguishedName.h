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

#import "OFASN1Set.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFX500RelativeDistinguishedName OFX500RelativeDistinguishedName.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An X.500 RelativeDistinguishedName.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX500RelativeDistinguishedName: OFASN1Set
/**
 * @brief The SET OF AttributeTypeAndValue of the X.500
 *	  RelativeDistinguishedName.
 */
@property (readonly, retain, nonatomic) OFArray OF_GENERIC(
    OFX500RelativeDistinguishedName *) *attributeTypesAndValues;
@end

OF_ASSUME_NONNULL_END
