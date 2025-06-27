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
#import "OFASN1DERRepresentation.h"
#import "OFJSONRepresentation.h"
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFNull OFNull.h ObjFW/ObjFW.h
 *
 * @brief A class for representing null values in collections.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFNull: OFObject <OFCopying, OFJSONRepresentation,
    OFMessagePackRepresentation, OFASN1DERRepresentation>
/**
 * @brief Returns an OFNull singleton.
 *
 * @return An OFNull singleton
 */
+ (OFNull *)null;
@end

OF_ASSUME_NONNULL_END
