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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFInvalidJSONException \
 *	  OFInvalidJSONException.h ObjFW/OFInvalidJSONException.h
 *
 * @brief An exception indicating a JSON representation is invalid.
 */
@interface OFInvalidJSONException: OFException
{
	OFString *_string;
	size_t _line;
}

/*!
 * The string containing the invalid JSON representation.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *string;

/*!
 * The line in which parsing the JSON representation failed.
 */
@property (readonly, nonatomic) size_t line;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased invalid JSON exception.
 *
 * @param string The string containing the invalid JSON representation
 * @param line The line in which the parsing error was encountered
 * @return A new, autoreleased invalid JSON exception
 */
+ (instancetype)exceptionWithString: (nullable OFString *)string
			       line: (size_t)line;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated invalid JSON exception.
 *
 * @param string The string containing the invalid JSON representation
 * @param line The line in which the parsing error was encountered
 * @return An initialized invalid JSON exception
 */
- initWithString: (nullable OFString *)string
	    line: (size_t)line OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
