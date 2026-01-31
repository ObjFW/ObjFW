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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFString;

/**
 * @class OFINISection OFINISection.h ObjFW/ObjFW.h
 *
 * @brief A class for representing a section of an INI file.
 */
@interface OFINISection: OFObject
{
	OFString *_name;
	OFMutableArray *_lines;
	OF_RESERVE_IVARS(OFINISection, 4)
}

/**
 * @brief The name of the INI section
 */
@property (copy, nonatomic) OFString *name;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Returns the string for the specified key, or `nil` if it does not
 *	  exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the string should be returned
 * @return The string for the specified key, or `nil` if it does not exist
 */
- (nullable OFString *)stringValueForKey: (OFString *)key;

/**
 * @brief Returns the string for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the string should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The string for the specified key or the specified default value if
 *	   it does not exist
 */
- (nullable OFString *)stringValueForKey: (OFString *)key
			    defaultValue: (nullable OFString *)defaultValue;

/**
 * @brief Returns the `long long` value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the long long should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The long long for the specified key or the specified default value
 *	   if it does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a long long
 */
- (long long)longLongValueForKey: (OFString *)key
		    defaultValue: (long long)defaultValue;

/**
 * @brief Returns the `unsigned long long` value for the specified key or the
 *	  specified default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the long long should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The long long for the specified key or the specified default value
 *	   if it does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a long long
 */
- (unsigned long long)
    unsignedLongLongValueForKey: (OFString *)key
		   defaultValue: (unsigned long long)defaultValue;

/**
 * @brief Returns the bool value for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the bool should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The bool for the specified key or the specified default value if it
 *	   does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a bool
 */
- (bool)boolValueForKey: (OFString *)key defaultValue: (bool)defaultValue;

/**
 * @brief Returns the float value for the specified key or the specified default
 *	  value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the float should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The float for the specified key or the specified default value if it
 *	   does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a float
 */
- (float)floatValueForKey: (OFString *)key defaultValue: (float)defaultValue;

/**
 * @brief Returns the double value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is returned.
 *
 * @param key The key for which the double should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The double for the specified key or the specified default value if
 *	   it does not exist
 * @throw OFInvalidFormatException The specified key is not in the correct
 *				   format for a double
 */
- (double)doubleValueForKey: (OFString *)key defaultValue: (double)defaultValue;

/**
 * @brief Returns an array of strings for the specified multi-key, or an empty
 *	  array if the key does not exist.
 *
 * A multi-key is a key which exists several times in the same section. Each
 * occurrence of the key/value pair adds the respective value to the array.
 *
 * @param key The multi-key for which the array should be returned
 * @return The array for the specified key, or an empty array if it does not
 *	   exist
 */
- (OFArray OF_GENERIC(OFString *) *)arrayValueForKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified string.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param stringValue The string to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setStringValue: (OFString *)stringValue forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified `long long`.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param longLongValue The `long long` to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setLongLongValue: (long long)longLongValue forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified
 *	  `unsigned long long`.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param unsignedLongLongValue The `unsigned long long` to which the key
 *				should be set
 * @param key The key for which the new value should be set
 */
- (void)setUnsignedLongLongValue: (unsigned long long)unsignedLongLongValue
			  forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified bool.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param boolValue The bool to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setBoolValue: (bool)boolValue forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified float.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param floatValue The float to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setFloatValue: (float)floatValue forKey: (OFString *)key;

/**
 * @brief Sets the value of the specified key to the specified double.
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), the value
 * of the first key/value pair found is changed.
 *
 * @param doubleValue The double to which the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setDoubleValue: (double)doubleValue forKey: (OFString *)key;

/**
 * @brief Sets the specified multi-key to the specified array of strings.
 *
 * It replaces the first occurrence of the multi-key with several key/value
 * pairs and removes all following occurrences. If the multi-key does not exist
 * yet, it is appended to the section.
 *
 * See also @ref arrayValueForKey: for more information about multi-keys.
 *
 * @param arrayValue The array of strings to which the multi-key should be set
 * @param key The multi-key for which the new values should be set
 */
- (void)setArrayValue: (OFArray OF_GENERIC(OFString *) *)arrayValue
	       forKey: (OFString *)key;

/**
 * @brief Removes the value for the specified key
 *
 * If the specified key is a multi-key (see @ref arrayValueForKey:), all
 * key/value pairs matching the specified key are removed.
 *
 * @param key The key of the value to remove
 */
- (void)removeValueForKey: (OFString *)key;
@end

OF_ASSUME_NONNULL_END
