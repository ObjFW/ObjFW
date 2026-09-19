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

#import "OFASN1TextString.h"
#import "OFCharacterSet.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @brief An ASN.1 PrintableString.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFASN1PrintableString: OFASN1TextString
@end

@interface OFCharacterSet (ASN1PrintableStringCharacterSet)
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFCharacterSet *ASN1PrintableStringCharacterSet;
#endif

/**
 * @brief Returns the characters allowed in an OFASN1PrintableString.
 *
 * @return The characters allowed in an OFASN1PrintableString
 */
+ (OFCharacterSet *)ASN1PrintableStringCharacterSet;
@end

OF_ASSUME_NONNULL_END
