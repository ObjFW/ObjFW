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

@class OFString;

OF_ASSUME_NONNULL_BEGIN

enum {
	OF_JSON_REPRESENTATION_PRETTY	  = 0x01,
	OF_JSON_REPRESENTATION_JSON5	  = 0x02,
	OF_JSON_REPRESENTATION_IDENTIFIER = 0x10
};

/*!
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
/*!
 * @brief The JSON representation of the object as a string.
 */
@property (readonly, nonatomic) OFString *JSONRepresentation;

/*!
 * @brief Returns the JSON representation of the object as a string.
 *
 * @param options The options to use when creating a JSON representation.@n
 *		  Possible values are:
 *		  Value                           | Description
 *		  --------------------------------|-------------------------
 *		  `OF_JSON_REPRESENTATION_PRETTY` | Optimize for readability
 *		  `OF_JSON_REPRESENTATION_JSON5`  | Generate JSON5
 *
 * @return The JSON representation of the object as a string
 */
- (OFString *)JSONRepresentationWithOptions: (int)options;
@end

OF_ASSUME_NONNULL_END
