/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#import "OFData.h"
#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFData_ASN1DERValue_reference;
#ifdef __cplusplus
}
#endif

@interface OFData (ASN1DERValue)
/*!
 * @brief The data interpreted as ASN.1 in DER representation and parsed as an
 *	  object.
 *
 * This is either an OFArray (for a sequence), an OFSet (for a set) or an
 * OFASN1Value.
 */
@property (readonly, nonatomic) id ASN1DERValue;

/*!
 * @brief Parses the ASN.1 DER representation and returns it as an object.
 *
 * This is either an OFArray (for a sequence), an OFSet (for a set) or an
 * OFASN1Value.
 *
 * @param depthLimit The maximum depth the parser should accept (defaults to 32
 *		     if not specified, 0 means no limit (insecure!))
 * @return The ASN.1 DER representation as an object
 */
- (id)ASN1DERValueWithDepthLimit: (size_t)depthLimit;
@end

OF_ASSUME_NONNULL_END
