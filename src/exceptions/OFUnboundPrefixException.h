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

OF_ASSUME_NONNULL_BEGIN

@class OFXMLParser;

/**
 * @class OFUnboundPrefixException OFUnboundPrefixException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating an attempt to use an unbound prefix.
 */
@interface OFUnboundPrefixException: OFException
{
	OFString *_prefix;
	OFXMLParser *_parser;
	OF_RESERVE_IVARS(OFUnboundPrefixException, 4)
}

/**
 * @brief The unbound prefix.
 */
@property (readonly, nonatomic) OFString *prefix;

/**
 * @brief The parser which encountered the unbound prefix.
 */
@property (readonly, nonatomic) OFXMLParser *parser;

/**
 * @brief Creates a new, autoreleased unbound prefix exception.
 *
 * @param prefix The prefix which is unbound
 * @param parser The parser which encountered the unbound prefix
 * @return A new, autoreleased unbound prefix exception
 */
+ (instancetype)exceptionWithPrefix: (OFString *)prefix
			     parser: (OFXMLParser *)parser;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated unbound prefix exception.
 *
 * @param prefix The prefix which is unbound
 * @param parser The parser which encountered the unbound prefix
 * @return An initialized unbound prefix exception
 */
- (instancetype)initWithPrefix: (OFString *)prefix
			parser: (OFXMLParser *)parser OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
