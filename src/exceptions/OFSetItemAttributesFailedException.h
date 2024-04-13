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
#import "OFIRIHandler.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;

/**
 * @class OFSetItemAttributesFailedException \
 *	  OFSetItemAttributesFailedException.h \
 *	  ObjFW/OFSetItemAttributesFailedException.h
 *
 * @brief An exception indicating an item's attributes could not be set.
 */
@interface OFSetItemAttributesFailedException: OFException
{
	OFIRI *_IRI;
	OFFileAttributes _attributes;
	OFFileAttributeKey _failedAttribute;
	int _errNo;
	OF_RESERVE_IVARS(OFSetItemAttributesFailedException, 4)
}

/**
 * @brief The IRI of the item whose attributes could not be set.
 */
@property (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief The attributes that should have been set.
 */
@property (readonly, nonatomic) OFFileAttributes attributes;

/**
 * @brief The first attribute that could not be set.
 */
@property (readonly, nonatomic) OFFileAttributeKey failedAttribute;

/**
 * @brief Creates a new, autoreleased set item attributes failed exception.
 *
 * @param IRI The IRI of the item whose attributes could not be set
 * @param attributes The attributes that should have been set for the specified
 *		     item.
 * @param failedAttribute The first attribute that could not be set
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased set item attributes failed exception
 */
+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
		      attributes: (OFFileAttributes)attributes
		 failedAttribute: (OFFileAttributeKey)failedAttribute
			   errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated set item attributes failed exception.
 *
 * @param IRI The IRI of the item whose attributes could not be set
 * @param attributes The attributes that should have been set for the specified
 *		     item.
 * @param failedAttribute The first attribute that could not be set
 * @param errNo The errno of the error that occurred
 * @return An initialized set item attributes failed exception
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		 attributes: (OFFileAttributes)attributes
	    failedAttribute: (OFFileAttributeKey)failedAttribute
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
