/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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
#import "OFMessagePackRepresentation.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDataArray;

/*!
 * @class OFMessagePackExtension \
 *	  OFMessagePackExtension.h ObjFW/OFMessagePackExtension.h
 *
 * @brief A class for representing the MessagePack extension type.
 */
@interface OFMessagePackExtension: OFObject <OFMessagePackRepresentation,
    OFCopying>
{
	int8_t _type;
	OFDataArray *_data;
}

/*!
 * The MessagePack extension type.
 */
@property (readonly) int8_t type;

/*!
 * @return The data of the extension.
 */
@property (readonly, nonatomic) OFDataArray *data;

/*!
 * @brief Creates a new OFMessagePackRepresentation with the specified type and
 *	  data.
 *
 * @param type The MessagePack extension type
 * @param data The data for the extension
 * @return A new, autoreleased OFMessagePackRepresentation
 */
+ (instancetype)extensionWithType: (int8_t)type
			     data: (OFDataArray*)data;

/*!
 * @brief Initializes an already allocated OFMessagePackRepresentation with the
 *	  specified type and data.
 *
 * @param type The MessagePack extension type
 * @param data The data for the extension
 * @return An initialized OFMessagePackRepresentation
 */
- initWithType: (int8_t)type
	  data: (OFDataArray*)data;
@end

OF_ASSUME_NONNULL_END
