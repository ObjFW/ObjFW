/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFCopyItemFailedException OFCopyItemFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that copying a item failed.
 */
@interface OFCopyItemFailedException: OFException
{
	OFIRI *_sourceIRI, *_destinationIRI;
	int _errNo;
	OF_RESERVE_IVARS(OFCopyItemFailedException, 4)
}

/**
 * @brief The IRI of the source item.
 */
@property (readonly, nonatomic) OFIRI *sourceIRI;

/**
 * @brief The destination IRI.
 */
@property (readonly, nonatomic) OFIRI *destinationIRI;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased copy item failed exception.
 *
 * @param sourceIRI The IRI of the source item
 * @param destinationIRI The destination IRI
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased copy item failed exception
 */
+ (instancetype)exceptionWithSourceIRI: (OFIRI *)sourceIRI
			destinationIRI: (OFIRI *)destinationIRI
				 errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated copy item failed exception.
 *
 * @param sourceIRI The IRI of the source item
 * @param destinationIRI The destination IRI
 * @param errNo The errno of the error that occurred
 * @return An initialized copy item failed exception
 */
- (instancetype)initWithSourceIRI: (OFIRI *)sourceIRI
		   destinationIRI: (OFIRI *)destinationIRI
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
