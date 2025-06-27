/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFData.h"
#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFData_ASN1DERParsing_reference;
#ifdef __cplusplus
}
#endif

@interface OFData (ASN1DERParsing)
/**
 * @brief The data interpreted as ASN.1 in DER representation and parsed as an
 *	  object.
 *
 * This is either an OFArray (for a sequence), an OFSet (for a set) or an
 * OFASN1Value.
 */
@property (readonly, nonatomic) id objectByParsingASN1DER;

/**
 * @brief Parses the ASN.1 DER representation and returns it as an object.
 *
 * This is either an OFArray (for a sequence), an OFSet (for a set) or an
 * OFASN1Value.
 *
 * @param depthLimit The maximum depth the parser should accept (defaults to 32
 *		     if not specified, 0 means no limit (insecure!))
 * @return The ASN.1 DER representation as an object
 */
- (id)objectByParsingASN1DERWithDepthLimit: (size_t)depthLimit;
@end

OF_ASSUME_NONNULL_END
