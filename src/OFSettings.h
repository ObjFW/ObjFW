/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

@class OFString;
@class OFArray OF_GENERIC(ObjectType);

/**
 * @class OFSettings OFSettings.h ObjFW/OFSettings.h
 *
 * Paths are delimited by dots, for example `category.subcategory.key`.
 *
 * @note The behaviour when accessing a path with a different type than it has
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
 * @brief Sets the specified path to the specified string value.
 *
 * @param stringValue The string value to set
 * @param path The path to store the string value at
 */
- (void)setStringValue: (OFString *)stringValue
	       forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified long long value.
 *
 * @param longLongValue The long long value to set
 * @param path The path to store the long long value at
 */
- (void)setLongLongValue: (long long)longLongValue
		 forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified bool value.
 *
 * @param boolValue The bool value to set
 * @param path The path to store the bool value at
 */
- (void)setBoolValue: (bool)boolValue
	     forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified float value.
 *
 * @param floatValue The float value to set
 * @param path The path to store the float value at
 */
- (void)setFloatValue: (float)floatValue
	      forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified double value.
 *
 * @param doubleValue The double value to set
 * @param path The path to store the double value at
 */
- (void)setDoubleValue: (double)doubleValue
	       forPath: (OFString *)path;

/**
 * @brief Sets the specified path to the specified array of string values.
 *
 * @param stringValues The array of string values to set
 * @param path The path to store the array of string values at
 */
- (void)setStringValues: (OFArray OF_GENERIC(OFString *) *)stringValues
		forPath: (OFString *)path;

/**
 * @brief Returns the string value for the specified path, or `nil` if the path
 *	  does not exist.
 *
 * @param path The path for which the string value should be returned
 * @return The string value of the specified path
 */
- (nullable OFString *)stringValueForPath: (OFString *)path;

/**
 * @brief Returns the string value for the specified path, or the default value
 *	  if the path does not exist.
 *
 * @param path The path for which the string value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The string value of the specified path
 */
- (nullable OFString *)stringValueForPath: (OFString *)path
			     defaultValue: (nullable OFString *)defaultValue;

/**
 * @brief Returns the long long value for the specified path, or the default
 *	  value if the path does not exist.
 *
 * @param path The path for which the long long value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The long long value of the specified path
 */
- (long long)longLongValueForPath: (OFString *)path
		     defaultValue: (long long)defaultValue;

/**
 * @brief Returns the bool value for the specified path, or the default value if
 *	  the path does not exist.
 *
 * @param path The path for which the bool value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The bool value of the specified path
 */
- (bool)boolValueForPath: (OFString *)path
	    defaultValue: (bool)defaultValue;

/**
 * @brief Returns the float value for the specified path, or the default value
 *	  if the path does not exist.
 *
 * @param path The path for which the float value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The float value of the specified path
 */
- (float)floatValueForPath: (OFString *)path
	      defaultValue: (float)defaultValue;

/**
 * @brief Returns the double value for the specified path, or the default value
 *	  if the path does not exist.
 *
 * @param path The path for which the double value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The double value of the specified path
 */
- (double)doubleValueForPath: (OFString *)path
		defaultValue: (double)defaultValue;

/**
 * @brief Returns the array of string values for the specified path, or an empty
 *	  array if the path does not exist.
 *
 * @param path The path for which the array of string values should be returned
 * @return The array of string values of the specified path
 */
- (OFArray OF_GENERIC(OFString *) *)stringValuesForPath: (OFString *)path;

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
