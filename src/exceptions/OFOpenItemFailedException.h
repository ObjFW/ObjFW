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
 * @class OFOpenItemFailedException OFOpenItemFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating an item could not be opened.
 */
@interface OFOpenItemFailedException: OFException
{
	OFIRI *_Nullable _IRI;
	OFString *_Nullable _path;
	OFString *_mode;
	int _errNo;
	OF_RESERVE_IVARS(OFOpenItemFailedException, 4)
}

/**
 * @brief The IRI of the item which could not be opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief The path of the item which could not be opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief The mode in which the item should have been opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *mode;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param IRI The IRI of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
			    mode: (nullable OFString *)mode
			   errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param path The path of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (nullable OFString *)mode
			    errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param IRI The IRI of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return An initialized open item failed exception
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		       mode: (nullable OFString *)mode
		      errNo: (int)errNo;

/**
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param path The path of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return An initialized open item failed exception
 */
- (instancetype)initWithPath: (OFString *)path
			mode: (nullable OFString *)mode
		       errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
