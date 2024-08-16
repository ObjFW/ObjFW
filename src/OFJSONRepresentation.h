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

@class OFString;

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief Options to change the behavior when creating a JSON representation.
 */
typedef enum {
	/** Optimize for readability */
	OFJSONRepresentationOptionPretty       = 0x01,
	/** Generate JSON5 */
	OFJSONRepresentationOptionJSON5	       = 0x02,
	/** Sort keys alphabetically */
	OFJSONRepresentationOptionSorted       = 0x04,
	OFJSONRepresentationOptionIsIdentifier = 0x10
} OFJSONRepresentationOptions;

/**
 * @protocol OFJSONRepresentation OFJSONRepresentation.h ObjFW/ObjFW.h
 *
 * @brief A protocol implemented by classes that support encoding to a JSON
 *	  representation.
 *
 * @warning Although this method can be called directly on classes other than
 *	    OFArray and OFDictionary, this will generate invalid JSON, as JSON
 *	    requires all data to be encapsulated in an array or a dictionary!
 */
@protocol OFJSONRepresentation
/**
 * @brief The JSON representation of the object as a string.
 */
@property (readonly, nonatomic) OFString *JSONRepresentation;

/**
 * @brief Returns the JSON representation of the object as a string.
 *
 * @param options The options to use when creating a JSON representation
 * @return The JSON representation of the object as a string
 */
- (OFString *)JSONRepresentationWithOptions:
    (OFJSONRepresentationOptions)options;
@end

OF_ASSUME_NONNULL_END
