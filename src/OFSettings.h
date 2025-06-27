/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

@class OFString;
@class OFArray OF_GENERIC(ObjectType);

/**
 * @class OFSettings OFSettings.h ObjFW/ObjFW.h
 *
 * Paths are delimited by dots, for example `category.subcategory.key`.
 *
 * @note The behavior when accessing a path with a different type than it has
 *	 been accessed with before is undefined! If you want to change the type
 *	 for a path, remove it and then set it with the new type.
 *
 * @brief A class for storing and retrieving settings
 */
@interface OFSettings: OFObject
{
	OFString *_applicationName;
	OF_RESERVE_IVARS(OFSettings, 4)
}

/**
 * @brief The name of the application whose settings are accessed by the
 *	  instance.
 */
@property (readonly, nonatomic) OFString *applicationName;

/**
 * @brief Create a new OFSettings instance for the application with the
 *	  specified name.
 *
 * @param applicationName The name of the application whose settings should be
 *			  accessed
 * @return A new, autoreleased OFSettings instance
 */
+ (instancetype)settingsWithApplicationName: (OFString *)applicationName;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFSettings instance with the
 *	  specified application name.
 *
 * @param applicationName The name of the application whose settings should be
 *			  accessed
 * @return An initialized OFSettings instance
 */
- (instancetype)initWithApplicationName: (OFString *)applicationName
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Sets the specified path to the specified string.
 *
 * @param string The string to set
 * @param path The path to store the string at
 */
- (void)setString: (OFString *)string forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified `long long`.
 *
 * @param longLong The `long long` to set
 * @param path The path to store the `long long` at
 */
- (void)setLongLong: (long long)longLong forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified `unsigned long long`.
 *
 * @param unsignedLongLong The `unsigned long long` to set
 * @param path The path to store the `unsigned long long` at
 */
- (void)setUnsignedLongLong: (unsigned long long)unsignedLongLong
		    forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified bool.
 *
 * @param bool_ The bool to set
 * @param path The path to store the bool at
 */
- (void)setBool: (bool)bool_ forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified float.
 *
 * @param float_ The float to set
 * @param path The path to store the float at
 */
- (void)setFloat: (float)float_ forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified double.
 *
 * @param double_ The double to set
 * @param path The path to store the double at
 */
- (void)setDouble: (double)double_ forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified array of strings.
 *
 * @param array The array of strings to set
 * @param path The path to store the array of string at
 */
- (void)setStringArray: (OFArray OF_GENERIC(OFString *) *)array
	       forPath: (OFString *)path;

/**
 * @brief Returns the string for the specified path, or `nil` if the path does
 *	  not exist.
 *
 * @param path The path for which the string should be returned
 * @return The string of the specified path
 */
- (nullable OFString *)stringForPath: (OFString *)path;

/**
 * @brief Returns the string for the specified path, or the default value if
 *	  the path does not exist.
 *
 * @param path The path for which the string should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The string of the specified path
 */
- (nullable OFString *)stringForPath: (OFString *)path
			defaultValue: (nullable OFString *)defaultValue;

/**
 * @brief Returns the `long long` for the specified path, or the default value
 *	  if the path does not exist.
 *
 * @param path The path for which the `long long` should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The `long long` of the specified path
 */
- (long long)longLongForPath: (OFString *)path
		defaultValue: (long long)defaultValue;

/**
 * @brief Returns the `unsigned long long` for the specified path, or the
 *	  default value if the path does not exist.
 *
 * @param path The path for which the `unsigned long long` should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The `unsigned long long` of the specified path
 */
- (unsigned long long)unsignedLongLongForPath: (OFString *)path
				 defaultValue: (unsigned long long)defaultValue;

/**
 * @brief Returns the bool for the specified path, or the default value if the
 *	  path does not exist.
 *
 * @param path The path for which the bool should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The bool of the specified path
 */
- (bool)boolForPath: (OFString *)path defaultValue: (bool)defaultValue;

/**
 * @brief Returns the float for the specified path, or the default value if the
 *	  path does not exist.
 *
 * @param path The path for which the float should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The float of the specified path
 */
- (float)floatForPath: (OFString *)path defaultValue: (float)defaultValue;

/**
 * @brief Returns the double for the specified path, or the default value if
 *	  the path does not exist.
 *
 * @param path The path for which the double should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The double of the specified path
 */
- (double)doubleForPath: (OFString *)path defaultValue: (double)defaultValue;

/**
 * @brief Returns the array of strings for the specified path, or an empty
 *	  array if the path does not exist.
 *
 * @param path The path for which the array of strings should be returned
 * @return The array of string values of the specified path
 */
- (OFArray OF_GENERIC(OFString *) *)stringArrayForPath: (OFString *)path;

/**
 * @brief Removes the value for the specified path.
 *
 * @param path The path for which the value should be removed
 */
- (void)removeValueForPath: (OFString *)path;

/**
 * @brief Saves the settings to disk.
 *
 * @warning Some backends might save the settings instantly, others might not
 *	    save them before calling this method for performance reasons. You
 *	    should always call this method after doing a bunch of changes, no
 *	    matter which backend is used!
 */
- (void)save;
@end

OF_ASSUME_NONNULL_END
