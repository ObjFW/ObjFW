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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFString;

/*!
 * @class OFINICategory OFINICategory.h ObjFW/OFINICategory.h
 *
 * @brief A class for representing a category of an INI file.
 */
@interface OFINICategory: OFObject
{
	OFString *_name;
	OFMutableArray *_lines;
}

/*!
 * The name of the INI category
 */
@property (nonatomic, copy) OFString *name;

- init OF_UNAVAILABLE;

/*!
 * @brief Returns the string value for the specified key, or `nil` if it does
 *	  not exist.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is returned.
 *
 * @param key The key for which the string value should be returned
 * @return The string value for the specified key, or `nil` if it does not exist
 */
- (nullable OFString *)stringForKey: (OFString *)key;

/*!
 * @brief Returns the string value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is returned.
 *
 * @param key The key for which the string value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The string value for the specified key or the specified default
 *	   value if it does not exist
 */
- (nullable OFString *)stringForKey: (OFString *)key
		       defaultValue: (nullable OFString *)defaultValue;

/*!
 * @brief Returns the integer value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is returned.
 *
 * @param key The key for which the integer value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The integer value for the specified key or the specified default
 *	   value if it does not exist
 */
- (intmax_t)integerForKey: (OFString *)key
	     defaultValue: (intmax_t)defaultValue;

/*!
 * @brief Returns the bool value for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is returned.
 *
 * @param key The key for which the bool value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The bool value for the specified key or the specified default value
 *	   if it does not exist
 */
- (bool)boolForKey: (OFString *)key
      defaultValue: (bool)defaultValue;

/*!
 * @brief Returns the float value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is returned.
 *
 * @param key The key for which the float value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The float value for the specified key or the specified default value
 *	   if it does not exist
 */
- (float)floatForKey: (OFString *)key
	defaultValue: (float)defaultValue;

/*!
 * @brief Returns the double value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is returned.
 *
 * @param key The key for which the double value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The double value for the specified key or the specified default
 *	   value if it does not exist
 */
- (double)doubleForKey: (OFString *)key
	  defaultValue: (double)defaultValue;

/*!
 * @brief Returns an array of string values for the specified multi-key, or an
 *	  empty array if the key does not exist.
 *
 * A multi-key is a key which exists several times in the same category. Each
 * occurrence of the key/value pair adds the respective value to the array.
 *
 * @param key The multi-key for which the array should be returned
 * @return The array for the specified key, or an empty array if it does not
 *	   exist
 */
- (OFArray OF_GENERIC(OFString *) *)arrayForKey: (OFString *)key;

/*!
 * @brief Sets the value of the specified key to the specified string.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is changed.
 *
 * @param string The string to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setString: (OFString *)string
	   forKey: (OFString *)key;

/*!
 * @brief Sets the value of the specified key to the specified integer.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is changed.
 *
 * @param integer The integer to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setInteger: (intmax_t)integer
	    forKey: (OFString *)key;

/*!
 * @brief Sets the value of the specified key to the specified bool.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is changed.
 *
 * @param bool_ The bool to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setBool: (bool)bool_
	 forKey: (OFString *)key;

/*!
 * @brief Sets the value of the specified key to the specified float.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is changed.
 *
 * @param float_ The float to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setFloat: (float)float_
	  forKey: (OFString *)key;

/*!
 * @brief Sets the value of the specified key to the specified double.
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), the value of
 * the first key/value pair found is changed.
 *
 * @param double_ The double to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setDouble: (double)double_
	   forKey: (OFString *)key;

/*!
 * @brief Sets the specified multi-key to the specified array of strings.
 *
 * It replaces the first occurrence of the multi-key with several key/value
 * pairs and removes all following occurrences. If the multi-key does not exist
 * yet, it is appended to the section.
 *
 * See also @ref arrayForKey: for more information about multi-keys.
 *
 * @param array The array of strings to which the multi-key should be set
 * @param key The multi-key for which the new values should be set
 */
- (void)setArray: (OFArray OF_GENERIC(OFString *) *)array
	  forKey: (OFString *)key;

/*!
 * @brief Removes the value for the specified key
 *
 * If the specified key is a multi-key (see @ref arrayForKey:), all key/value
 * pairs matching the specified key are removed.
 *
 * @param key The key of the value to remove
 */
- (void)removeValueForKey: (OFString *)key;
@end

OF_ASSUME_NONNULL_END
