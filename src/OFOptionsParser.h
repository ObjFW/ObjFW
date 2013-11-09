/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFObject.h"
#import "OFConstantString.h"

/*!
 * @brief A class for parsing the program options specified on the command line.
 */
@interface OFOptionsParser: OFObject
{
	of_unichar_t *_options;
	OFArray *_arguments;
	size_t _index, _subIndex;
	of_unichar_t _lastOption;
	OFString *_argument;
	bool _done;
}

/*!
 * @brief Creates a new OFOptionsParser which accepts the specified options.
 *
 * @param options A string listing the acceptable options.@n
 *		  Options that require an argument are immediately followed by
 *		  ':'.
 *
 * @return A new, autoreleased OFOptionsParser
 */
+ (instancetype)parserWithOptions: (OFString*)options;

/*!
 * @brief Initializes an already allocated OFOptionsParser so that it accepts
 *	  the specified options.
 *
 * @param options A string listing the acceptable options.@n
 *		  Options that require an argument are immediately followed by
 *		  ':'.
 *
 * @return An initialized OFOptionsParser
 */
- initWithOptions: (OFString*)options;

/*!
 * @brief Returns the next option.
 *
 * If an unknown option is specified, '?' is returned.@n
 * If the argument for the option is missing, ':' is returned.@n
 * If all options have been parsed, '\0' is returned.
 *
 * @return The next option
 */
- (of_unichar_t)nextOption;

/*!
 * @brief Returns the last parsed option.
 *
 * If @ref nextOption returned '?' or ':', this returns the option which was
 * unknown or for which the argument was missing.
 *
 * @return The last parsed option
 */
- (of_unichar_t)lastOption;

/*!
 * @brief Returns the argument for the last parsed option, or nil if the last
 *	  parsed option takes no argument.
 *
 * @return The argument for the last parsed option
 */
- (OFString*)argument;

/*!
 * @brief Returns the arguments following the last option.
 *
 * @return The arguments following the last option
 */
- (OFArray*)remainingArguments;
@end
