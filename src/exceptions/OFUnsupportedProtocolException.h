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

@class OFIRI;

/**
 * @class OFUnsupportedProtocolException OFUnsupportedProtocolException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that the protocol specified by the IRI is not
 *	  supported.
 */
@interface OFUnsupportedProtocolException: OFException
{
	OFIRI *_Nullable _IRI;
	OF_RESERVE_IVARS(OFUnsupportedProtocolException, 4)
}

/**
 * @brief The IRI whose protocol is unsupported.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief Creates a new, autoreleased unsupported protocol exception.
 *
 * @param IRI The IRI whose protocol is unsupported
 * @return A new, autoreleased unsupported protocol exception
 */
+ (instancetype)exceptionWithIRI: (nullable OFIRI *)IRI;

/**
 * @brief Initializes an already allocated unsupported protocol exception
 *
 * @param IRI The IRI whose protocol is unsupported
 * @return An initialized unsupported protocol exception
 */
- (instancetype)initWithIRI: (nullable OFIRI *)IRI OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
