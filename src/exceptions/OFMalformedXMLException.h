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

#import "OFException.h"

@class OFXMLParser;

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMalformedXMLException \
 *	  OFMalformedXMLException.h ObjFW/OFMalformedXMLException.h
 *
 * @brief An exception indicating that a parser encountered malformed XML.
 */
@interface OFMalformedXMLException: OFException
{
	OFXMLParser *_parser;
	OF_RESERVE_IVARS(OFMalformedXMLException, 4)
}

/**
 * @brief The parser which encountered malformed XML.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFXMLParser *parser;

/**
 * @brief Creates a new, autoreleased malformed XML exception.
 *
 * @param parser The parser which encountered malformed XML
 * @return A new, autoreleased malformed XML exception
 */
+ (instancetype)exceptionWithParser: (nullable OFXMLParser *)parser;

/**
 * @brief Initializes an already allocated malformed XML exception.
 *
 * @param parser The parser which encountered malformed XML
 * @return An initialized malformed XML exception
 */
- (instancetype)initWithParser: (nullable OFXMLParser *)parser
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
