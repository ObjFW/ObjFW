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

#import "OFPair.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutablePair OFMutablePair.h ObjFW/ObjFW.h
 *
 * @brief A class for storing a pair of two objects.
 */
@interface OFMutablePair OF_GENERIC(FirstType, SecondType):
    OFPair OF_GENERIC(FirstType, SecondType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define FirstType id
# define SecondType id
#endif
{
	OF_RESERVE_IVARS(OFMutablePair, 4)
}

/**
 * @brief The first object of the pair.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, retain)
    FirstType firstObject;

/**
 * @brief The second object of the pair.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, retain)
    SecondType secondObject;

/**
 * @brief Converts the mutable pair to an immutable pair.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
#endif
@end

OF_ASSUME_NONNULL_END
