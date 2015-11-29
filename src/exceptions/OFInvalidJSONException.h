/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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
@property (readonly, copy) OFString *string;

/*!
 * The line in which parsing the JSON representation failed.
 */
@property (readonly) size_t line;

/*!
 * @brief Creates a new, autoreleased invalid JSON exception.
 *
 * @param string The string containing the invalid JSON representation
 * @param line The line in which the parsing error encountered
 * @return A new, autoreleased invalid JSON exception
 */
+ (instancetype)exceptionWithString: (OFString*)string
			       line: (size_t)line;

/*!
 * @brief Initializes an already allocated invalid JSON exception.
 *
 * @param string The string containing the invalid JSON representation
 * @param line The line in which the parsing error encountered
 * @return An initialized invalid JSON exception
 */
- initWithString: (OFString*)string
	    line: (size_t)line;
@end
