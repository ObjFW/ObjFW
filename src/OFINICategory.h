/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

/**
 * @class OFINICategory OFINICategory.h ObjFW/OFINICategory.h
 *
 * @brief A class for representing a category of an INI file.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFINICategory: OFObject
{
	OFString *_name;
	OFMutableArray *_lines;
}

/**
 * @brief The name of the INI category
 */
@property (copy, nonatomic) OFString *name;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Returns the string for the specified key, or `nil` if it does not
 *	  exist.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the string should be returned
 * @return The string for the specified key, or `nil` if it does not exist
 */
- (nullable OFString *)stringForKey: (OFString *)key;

/**
 * @brief Returns the string for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the string should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The string for the specified key or the specified default value if
 *	   it does not exist
 */
- (nullable OFString *)stringForKey: (OFString *)key
		       defaultValue: (nullable OFString *)defaultValue;

/**
 * @brief Returns the long long for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the long long should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The long long for the specified key or the specified default value
 *	   if it does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a long long
 */
- (long long)longLongForKey: (OFString *)key
	       defaultValue: (long long)defaultValue;

/**
 * @brief Returns the bool for the specified key or the specified default value
 *	  if it does not exist.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the bool should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The bool for the specified key or the specified default value if it
 *	   does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a bool
 */
- (bool)boolForKey: (OFString *)key defaultValue: (bool)defaultValue;

/**
 * @brief Returns the float for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the float should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The float for the specified key or the specified default value if it
 *	   does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a float
 */
- (float)floatForKey: (OFString *)key defaultValue: (float)defaultValue;

/**
 * @brief Returns the double for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the double should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The double for the specified key or the specified default value if
 *	   it does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a double
 */
- (double)doubleForKey: (OFString *)key defaultValue: (double)defaultValue;

/**
 * @brief Returns an array of strings for the specified multi-key, or an empty
 *	  array if the key does not exist.
 *
 * A multi-key is a key which exists several times in the same category. Each
 * occurrence of the key/value pair adds the respective value to the array.
 *
 * @param key The multi-key for which the array should be returned
 * @return The array for the specified key, or an empty array if it does not
 *	   exist
 */
- (OFArray OF_GENERIC(OFString *) *)stringArrayForKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified string.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param string The string to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setString: (OFString *)string forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified long long.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param longLong The long long to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setLongLong: (long long)longLong forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified bool.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param bool_ The bool to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setBool: (bool)bool_ forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified float.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param float_ The float to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setFloat: (float)float_ forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified double.
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param double_ The double to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setDouble: (double)double_ forKey: (OFString *)key;

/**
 * @brief Sets the specified multi-key to the specified array of strings.
 *
 * It replaces the first occurrence of the multi-key with several key/value
 * pairs and removes all following occurrences. If the multi-key does not exist
 * yet, it is appended to the section.
 *
 * See also @ref stringArrayForKey: for more information about multi-keys.
 *
 * @param array The array of strings to which the multi-key should be set
 * @param key The multi-key for which the new values should be set
 */
- (void)setStringArray: (OFArray OF_GENERIC(OFString *) *)array
		forKey: (OFString *)key;

/**
 * @brief Removes the value for the specified key
 *
 * If the specified key is a multi-key (see @ref stringArrayForKey:), all
 * key/value pairs matching the specified key are removed.
 *
 * @param key The key of the value to remove
 */
- (void)removeValueForKey: (OFString *)key;
@end

OF_ASSUME_NONNULL_END
