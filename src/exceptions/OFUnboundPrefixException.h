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
 * The unbound prefix.
 */
@property (readonly, copy) OFString *prefix;

/*!
 * The parser which encountered the unbound prefix.
 */
@property (readonly, retain) OFXMLParser *parser;

/*!
 * @brief Creates a new, autoreleased unbound prefix exception.
 *
 * @param prefix The prefix which is unbound
 * @param parser The parser which encountered the unbound prefix
 * @return A new, autoreleased unbound prefix exception
 */
+ (instancetype)exceptionWithPrefix: (OFString*)prefix
			     parser: (OFXMLParser*)parser;

/*!
 * @brief Initializes an already allocated unbound prefix exception.
 *
 * @param prefix The prefix which is unbound
 * @param parser The parser which encountered the unbound prefix
 * @return An initialized unbound prefix exception
 */
- initWithPrefix: (OFString*)prefix
	  parser: (OFXMLParser*)parser;
@end
