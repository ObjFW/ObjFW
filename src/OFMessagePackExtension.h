/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @class OFMessagePackExtension \
 *	  OFMessagePackExtension.h ObjFW/OFMessagePackExtension.h
 *
 * @brief A class for representing the MessagePack extension type.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMessagePackExtension: OFObject <OFMessagePackRepresentation,
    OFCopying>
{
	int8_t _type;
	OFData *_data;
}

/**
 * @brief The MessagePack extension type.
 */
@property (readonly, nonatomic) int8_t type;

/**
 * @brief The data of the extension.
 */
@property (readonly, nonatomic) OFData *data;

/**
 * @brief Creates a new OFMessagePackRepresentation with the specified type and
 *	  data.
 *
 * @param type The MessagePack extension type
 * @param data The data for the extension
 * @return A new, autoreleased OFMessagePackRepresentation
 */
+ (instancetype)extensionWithType: (int8_t)type data: (OFData *)data;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFMessagePackRepresentation with the
 *	  specified type and data.
 *
 * @param type The MessagePack extension type
 * @param data The data for the extension
 * @return An initialized OFMessagePackRepresentation
 */
- (instancetype)initWithType: (int8_t)type
			data: (OFData *)data OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
