/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
 * @class OFMoveItemFailedException \
 *	  OFMoveItemFailedException.h ObjFW/OFMoveItemFailedException.h
 *
 * @brief An exception indicating that moving an item failed.
 */
@interface OFMoveItemFailedException: OFException
{
	OFIRI *_sourceIRI, *_destinationIRI;
	int _errNo;
	OF_RESERVE_IVARS(OFMoveItemFailedException, 4)
}

/**
 * @brief The original IRI.
 */
@property (readonly, nonatomic) OFIRI *sourceIRI;

/**
 * @brief The new IRI.
 */
@property (readonly, nonatomic) OFIRI *destinationIRI;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased move item failed exception.
 *
 * @param sourceIRI The original IRI
 * @param destinationIRI The new IRI
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased move item failed exception
 */
+ (instancetype)exceptionWithSourceIRI: (OFIRI *)sourceIRI
			destinationIRI: (OFIRI *)destinationIRI
				 errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated move item failed exception.
 *
 * @param sourceIRI The original IRI
 * @param destinationIRI The new IRI
 * @param errNo The errno of the error that occurred
 * @return An initialized move item failed exception
 */
- (instancetype)initWithSourceIRI: (OFIRI *)sourceIRI
		   destinationIRI: (OFIRI *)destinationIRI
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
