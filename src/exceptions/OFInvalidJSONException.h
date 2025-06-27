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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFInvalidJSONException OFInvalidJSONException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating a JSON representation is invalid.
 */
@interface OFInvalidJSONException: OFException
{
	OFString *_string;
	size_t _line;
	OF_RESERVE_IVARS(OFInvalidJSONException, 4)
}

/**
 * @brief The string containing the invalid JSON representation.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *string;

/**
 * @brief The line in which parsing the JSON representation failed.
 */
@property (readonly, nonatomic) size_t line;

/**
 * @brief Creates a new, autoreleased invalid JSON exception.
 *
 * @param string The string containing the invalid JSON representation
 * @param line The line in which the parsing error was encountered
 * @return A new, autoreleased invalid JSON exception
 */
+ (instancetype)exceptionWithString: (nullable OFString *)string
			       line: (size_t)line;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated invalid JSON exception.
 *
 * @param string The string containing the invalid JSON representation
 * @param line The line in which the parsing error was encountered
 * @return An initialized invalid JSON exception
 */
- (instancetype)initWithString: (nullable OFString *)string
			  line: (size_t)line OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
