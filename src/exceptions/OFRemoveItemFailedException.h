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
 * @class OFRemoveItemFailedException OFRemoveItemFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that removing an item failed.
 */
@interface OFRemoveItemFailedException: OFException
{
	OFIRI *_IRI;
	int _errNo;
	OF_RESERVE_IVARS(OFRemoveItemFailedException, 4)
}

/**
 * @brief The IRI of the item which could not be removed.
 */
@property (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased remove failed exception.
 *
 * @param IRI The IRI of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased remove item failed exception
 */
+ (instancetype)exceptionWithIRI: (OFIRI *)IRI errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated remove failed exception.
 *
 * @param IRI The IRI of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return An initialized remove item failed exception
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
