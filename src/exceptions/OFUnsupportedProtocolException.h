/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

@class OFURI;

/**
 * @class OFUnsupportedProtocolException \
 *	  OFUnsupportedProtocolException.h \
 *	  ObjFW/OFUnsupportedProtocolException.h
 *
 * @brief An exception indicating that the protocol specified by the URI is not
 *	  supported.
 */
@interface OFUnsupportedProtocolException: OFException
{
	OFURI *_Nullable _URI;
	OF_RESERVE_IVARS(OFUnsupportedProtocolException, 4)
}

/**
 * @brief The URI whose protocol is unsupported.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFURI *URI;

/**
 * @brief Creates a new, autoreleased unsupported protocol exception.
 *
 * @param URI The URI whose protocol is unsupported
 * @return A new, autoreleased unsupported protocol exception
 */
+ (instancetype)exceptionWithURI: (nullable OFURI*)URI;

/**
 * @brief Initializes an already allocated unsupported protocol exception
 *
 * @param URI The URI whose protocol is unsupported
 * @return An initialized unsupported protocol exception
 */
- (instancetype)initWithURI: (nullable OFURI*)URI OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
