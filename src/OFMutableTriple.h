/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFTriple.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMutableTriple OFMutableTriple.h ObjFW/OFMutableTriple.h
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
/*!
 * @brief The first object of the triple.
 */
@property (readwrite, nonatomic, retain) FirstType firstObject;

/*!
 * @brief The second object of the triple.
 */
@property (readwrite, nonatomic, retain) SecondType secondObject;

/*!
 * @brief The third object of the triple.
 */
@property (readwrite, nonatomic, retain) ThirdType thirdObject;

/*!
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
