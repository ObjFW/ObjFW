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

@class OFIRI;

/**
 * @class OFUnsupportedProtocolException \
 *	  OFUnsupportedProtocolException.h \
 *	  ObjFW/OFUnsupportedProtocolException.h
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
+ (instancetype)exceptionWithIRI: (nullable OFIRI*)IRI;

/**
 * @brief Initializes an already allocated unsupported protocol exception
 *
 * @param IRI The IRI whose protocol is unsupported
 * @return An initialized unsupported protocol exception
 */
- (instancetype)initWithIRI: (nullable OFIRI*)IRI OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
