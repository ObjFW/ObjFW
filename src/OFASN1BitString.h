/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/*!
 * @brief An ASN.1 bit string.
 */
@interface OFASN1BitString: OFASN1Value
{
	OFData *_bitStringValue;
	size_t _bitStringLength;
}

/*!
 * @brief The bit string value.
 */
@property (readonly, nonatomic) OFData *bitStringValue;

/*!
 * @brief The length of the bit string in bits.
 */
@property (readonly, nonatomic) size_t bitStringLength;
@end

OF_ASSUME_NONNULL_END
