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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @protocol OFASN1DERRepresentation \
 *	     OFASN1DERRepresentation.h ObjFW/OFASN1DERRepresentation.h
 *
 * @brief A protocol implemented by classes that support encoding to ASN.1 DER
 *	  representation.
 */
@protocol OFASN1DERRepresentation
/**
 * @brief The object in ASN.1 DER representation.
 */
@property (readonly, nonatomic) OFData *ASN1DERRepresentation;
@end

OF_ASSUME_NONNULL_END
