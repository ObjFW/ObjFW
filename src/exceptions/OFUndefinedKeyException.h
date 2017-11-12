/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFUndefinedKeyException \
 *	  OFUndefinedKeyException.h ObjFW/OFUndefinedKeyException.h
 *
 * @brief An exception indicating that a key is undefined (e.g. for Key Value
 *	  Coding).
 */
@interface OFUndefinedKeyException: OFException
{
	id _object;
	OFString *_key;
	id _Nullable _value;
}

/*!
 * The object on which the key is undefined.
 */
@property (readonly, nonatomic) id object;

/*!
 * The key which is undefined.
 */
@property (readonly, nonatomic) OFString *key;

/*!
 * The value for the undefined key
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id value;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 *
 * @return A new, autoreleased undefined key exception
 */
+ (instancetype)exceptionWithObject: (id)object
				key: (OFString *)key;

/*!
 * @brief Creates a new, autoreleased undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 * @param value The value for the undefined key
 *
 * @return A new, autoreleased undefined key exception
 */
+ (instancetype)exceptionWithObject: (id)object
				key: (OFString *)key
			      value: (nullable id)value;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 *
 * @return An initialized undefined key exception
 */
- (instancetype)initWithObject: (id)object
			   key: (OFString *)key;

/*!
 * @brief Initializes an already allocated undefined key exception.
 *
 * @param object The object on which the key is undefined
 * @param key The key which is undefined
 * @param value The value for the undefined key
 *
 * @return An initialized undefined key exception
 */
- (instancetype)initWithObject: (id)object
			   key: (OFString *)key
			 value: (nullable id)value OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
