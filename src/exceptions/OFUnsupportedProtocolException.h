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

@class OFURL;

/*!
 * @class OFUnsupportedProtocolException \
 *	  OFUnsupportedProtocolException.h \
 *	  ObjFW/OFUnsupportedProtocolException.h
 *
 * @brief An exception indicating that the protocol specified by the URL is not
 *	  supported.
 */
@interface OFUnsupportedProtocolException: OFException
{
	OFURL *_URL;
}

/*!
 * The URL whose protocol is unsupported.
 */
@property (readonly, nonatomic) OFURL *URL;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased unsupported protocol exception.
 *
 * @param URL The URL whose protocol is unsupported
 * @return A new, autoreleased unsupported protocol exception
 */
+ (instancetype)exceptionWithURL: (OFURL*)URL;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated unsupported protocol exception
 *
 * @param URL The URL whose protocol is unsupported
 * @return An initialized unsupported protocol exception
 */
- (instancetype)initWithURL: (OFURL*)URL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
