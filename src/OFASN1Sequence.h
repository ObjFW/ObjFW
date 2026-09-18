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

#import "OFConstructedASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief An ASN.1 Sequence.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1Sequence: OFConstructedASN1Value
/**
 * @brief Creates an ASN.1 Sequence with the specified components.
 *
 * @param components The components of the Sequence
 * @return A new, autoreleased OFASN1Sequence
 */
+ (instancetype)valueWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					 OFASN1Value *)) *)components;

/**
 * @brief Initializes an already allocated ASN.1 Sequence with the specified
 *	  components.
 *
 * @param components The components of the Sequence
 * @return An initialized OFASN1Sequence
 */
- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components;
@end

OF_ASSUME_NONNULL_END
