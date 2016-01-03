/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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
 * @class OFMalformedXMLException \
 *	  OFMalformedXMLException.h ObjFW/OFMalformedXMLException.h
 *
 * @brief An exception indicating that a parser encountered malformed XML.
 */
@interface OFMalformedXMLException: OFException
{
	OFXMLParser *_parser;
}

/*!
 * The parser which encountered malformed XML.
 */
@property (readonly, retain) OFXMLParser *parser;

/*!
 * @brief Creates a new, autoreleased malformed XML exception.
 *
 * @param parser The parser which encountered malformed XML
 * @return A new, autoreleased malformed XML exception
 */
+ (instancetype)exceptionWithParser: (OFXMLParser*)parser;

/*!
 * @brief Initializes an already allocated malformed XML exception.
 *
 * @param parser The parser which encountered malformed XML
 * @return An initialized malformed XML exception
 */
- initWithParser: (OFXMLParser*)parser;
@end
