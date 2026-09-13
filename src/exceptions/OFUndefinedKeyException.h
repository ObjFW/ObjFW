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

/**
 * @class OFUndefinedKeyException OFUndefinedKeyException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a key is undefined (e.g. for Key Value
 *	  Coding).
 */
@interface OFUndefinedKeyException: OFException
{
	id _object;
	OFString *_Nullable _key;
	id _Nullable _value;
	OF_RESERVE_IVARS(OFUndefinedKeyException, 4)
}

/**
 * @brief The object on which the key is undefined.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief The key which is undefined.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *key;

/**
 * @brief The value for the undefined key
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id value;

/**
 * @brief Creates a new, autoreleased undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 *
 * @return A new, autoreleased undefined key exception
 */
+ (instancetype)exceptionWithObject: (id)object key: (OFString *)key;

/**
 * @brief Creates a new, autoreleased undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 * @param value The value for the undefined key
 *
 * @return A new, autoreleased undefined key exception
 */
+ (instancetype)exceptionWithObject: (id)object
				key: (nullable OFString *)key
			      value: (nullable id)value;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 *
 * @return An initialized undefined key exception
 */
- (instancetype)initWithObject: (id)object key: (OFString *)key;

/**
 * @brief Initializes an already allocated undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 * @param value The value for the undefined key
 *
 * @return An initialized undefined key exception
 */
- (instancetype)initWithObject: (id)object
			   key: (nullable OFString *)key
			 value: (nullable id)value OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
