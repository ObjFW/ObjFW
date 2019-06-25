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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/*!
 * @protocol OFASN1DERRepresentation \
 *	     OFASN1DERRepresentation.h ObjFW/OFASN1DERRepresentation.h
 *
 * @brief A protocol implemented by classes that support encoding to ASN.1 DER
 *	  representation.
 */
@protocol OFASN1DERRepresentation
/*!
 * @brief The object in ASN.1 DER representation.
 */
@property (readonly, nonatomic) OFData *ASN1DERRepresentation;
@end

OF_ASSUME_NONNULL_END
