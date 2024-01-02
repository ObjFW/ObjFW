/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
