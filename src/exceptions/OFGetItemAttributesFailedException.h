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

@class OFIRI;

/**
 * @class OFGetItemAttributesFailedException
 *	  OFGetItemAttributesFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating an item's attributes could not be retrieved.
 */
@interface OFGetItemAttributesFailedException: OFException
{
	OFIRI *_IRI;
	int _errNo;
	OF_RESERVE_IVARS(OFGetItemAttributesFailedException, 4)
}

/**
 * @brief The IRI of the item whose attributes could not be retrieved.
 */
@property (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased retrieve item attributes failed exception.
 *
 * @param IRI The IRI of the item whose attributes could not be retrieved
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased retrieve item attributes failed exception
 */
+ (instancetype)exceptionWithIRI: (OFIRI *)IRI errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated retrieve item attributes failed
 *	  exception.
 *
 * @param IRI The IRI of the item whose attributes could not be retrieved
 * @param errNo The errno of the error that occurred
 * @return An initialized retrieve item attributes failed exception
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
