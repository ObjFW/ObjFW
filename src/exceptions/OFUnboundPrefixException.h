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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFXMLParser;

/*!
 * @class OFUnboundPrefixException \
 *	  OFUnboundPrefixException.h ObjFW/OFUnboundPrefixException.h
 *
 * @brief An exception indicating an attempt to use an unbound prefix.
 */
@interface OFUnboundPrefixException: OFException
{
	OFString *_prefix;
	OFXMLParser *_parser;
}

/*!
 * @brief The unbound prefix.
 */
@property (readonly, nonatomic) OFString *prefix;

/*!
 * @brief The parser which encountered the unbound prefix.
 */
@property (readonly, nonatomic) OFXMLParser *parser;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased unbound prefix exception.
 *
 * @param prefix The prefix which is unbound
 * @param parser The parser which encountered the unbound prefix
 * @return A new, autoreleased unbound prefix exception
 */
+ (instancetype)exceptionWithPrefix: (OFString *)prefix
			     parser: (OFXMLParser *)parser;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated unbound prefix exception.
 *
 * @param prefix The prefix which is unbound
 * @param parser The parser which encountered the unbound prefix
 * @return An initialized unbound prefix exception
 */
- (instancetype)initWithPrefix: (OFString *)prefix
			parser: (OFXMLParser *)parser OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
