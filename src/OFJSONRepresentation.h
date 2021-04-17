/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

@class OFString;

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief Options to change the behavior when creating a JSON representation.
 */
typedef enum OFJSONRepresentationOptions {
	/** Optimize for readability */
	OFJSONRepresentationOptionPretty       = 0x01,
	/** Generate JSON5 */
	OFJSONRepresentationOptionJSON5	       = 0x02,
	OFJSONRepresentationOptionIsIdentifier = 0x10
} OFJSONRepresentationOptions;

/**
 * @protocol OFJSONRepresentation
 *	     OFJSONRepresentation.h ObjFW/OFJSONRepresentation.h
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
