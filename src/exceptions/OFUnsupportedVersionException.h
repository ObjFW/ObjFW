/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
 * @class OFUnsupportedVersionException OFUnsupportedVersionException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that the specified version of the format or
 *	  protocol is not supported.
 */
@interface OFUnsupportedVersionException: OFException
{
	OFString *_version;
	OF_RESERVE_IVARS(OFUnsupportedVersionException, 4)
}

/**
 * @brief The version which is unsupported.
 */
@property (readonly, nonatomic) OFString *version;

/**
 * @brief Creates a new, autoreleased unsupported version exception.
 *
 * @param version The version which is unsupported
 * @return A new, autoreleased unsupported version exception
 */
+ (instancetype)exceptionWithVersion: (OFString *)version;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated unsupported protocol exception.
 *
 * @param version The version which is unsupported
 * @return An initialized unsupported version exception
 */
- (instancetype)initWithVersion: (OFString *)version OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
