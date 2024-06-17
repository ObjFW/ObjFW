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

#import "macros.h"

@class OFString;

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFKeyValueCoding OFKeyValueCoding.h ObjFW/ObjFW.h
 *
 * @brief A protocol for Key Value Coding.
 *
 * Key Value Coding makes it possible to access properties dynamically using
 * the interface described by this protocol.
 */
@protocol OFKeyValueCoding
/**
 * @brief Returns the value for the specified key.
 *
 * @param key The key of the value to return
 * @return The value for the specified key
 * @throw OFUndefinedKeyException The specified key does not exist and
 *				  @ref valueForUndefinedKey: was not overridden
 */
- (nullable id)valueForKey: (OFString *)key;

/**
 * @brief Returns the value for the specified key path.
 *
 * @param keyPath The key path of the value to return
 * @return The value for the specified key path
 * @throw OFUndefinedKeyException The specified key does not exist and
 *				  @ref valueForUndefinedKey: was not overridden
 */
- (nullable id)valueForKeyPath: (OFString *)keyPath;

/**
 * @brief This is called by @ref valueForKey: if the specified key does not
 *	  exist.
 *
 * By default, this throws an @ref OFUndefinedKeyException.
 *
 * @param key The undefined key of the value to return
 * @return The value for the specified undefined key
 * @throw OFUndefinedKeyException The specified key does not exist
 */
- (nullable id)valueForUndefinedKey: (OFString *)key;

/**
 * @brief Set the value for the specified key.
 *
 * @param value The value for the specified key
 * @param key The key of the value to set
 * @throw OFUndefinedKeyException The specified key does not exist and
 *				  @ref setValue:forUndefinedKey: was not
 *				  overridden
 */
- (void)setValue: (nullable id)value forKey: (OFString *)key;

/**
 * @brief Set the value for the specified key path.
 *
 * @param value The value for the specified key path
 * @param keyPath The key path of the value to set
 * @throw OFUndefinedKeyException The specified key does not exist and
 *				  @ref setValue:forUndefinedKey: was not
 *				  overridden
 */
- (void)setValue: (nullable id)value forKeyPath: (OFString *)keyPath;

/**
 * @brief This is called by @ref setValue:forKey: if the specified key does not
 *	  exist.
 *
 * By default, this throws an @ref OFUndefinedKeyException.
 *
 * @param value The value for the specified undefined key
 * @param key The undefined key of the value to set
 * @throw OFUndefinedKeyException The specified key does not exist
 */
-  (void)setValue: (nullable id)value forUndefinedKey: (OFString *)key;

/**
 * @brief This is called by @ref setValue:forKey: if the specified key is a
 *	  scalar, but the value specified is `nil`.
 *
 * By default, this throws an @ref OFInvalidArgumentException.
 *
 * @param key The key for which the value `nil` was specified
 */
- (void)setNilValueForKey: (OFString *)key;
@end

OF_ASSUME_NONNULL_END
