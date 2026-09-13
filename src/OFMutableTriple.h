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

#import "OFTriple.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFMutableTriple OFMutableTriple.h ObjFW/ObjFW.h
 *
 * @brief A class for storing a triple of three objects.
 */
@interface OFMutableTriple OF_GENERIC(FirstType, SecondType, ThirdType):
    OFTriple OF_GENERIC(FirstType, SecondType, ThirdType)
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define FirstType id
# define SecondType id
# define ThirdType id
#endif
{
	OF_RESERVE_IVARS(OFMutableTriple, 4)
}

/**
 * @brief The first object of the triple.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, retain)
    FirstType firstObject;

/**
 * @brief The second object of the triple.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, retain)
    SecondType secondObject;

/**
 * @brief The third object of the triple.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, retain)
    ThirdType thirdObject;

/**
 * @brief Converts the mutable triple to an immutable triple.
 */
- (void)makeImmutable;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
# undef ThirdType
#endif
@end

OF_ASSUME_NONNULL_END
