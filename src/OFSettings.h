/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

@class OFString;
@class OFArray OF_GENERIC(ObjectType);

/*!
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
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *applicationName;
#endif

/*!
 * @brief Create a new OFSettings instance for the application with the
 *	  specified name.
 *
 * @param applicationName The name of the application whose settings should be
 *			  accessed
 * @return A new, autoreleased OFSettings instance
 */
+ (instancetype)settingsWithApplicationName: (OFString*)applicationName;

/*!
 * @brief Initializes an already allocated OFSettings instance with the
 *	  specified application name.
 *
 * @param applicationName The name of the application whose settings should be
 *			  accessed
 * @return An initialized OFSettings instance
 */
- initWithApplicationName: (OFString*)applicationName;

/*!
 * @brief Returns the name of the application whose settings are accessed by
 *	  the instance
 *
 * @return The name of the application whose settings are accessed by the
 *	   instance
 */
- (OFString*)applicationName;

/*!
 * @brief Sets the specified path to the specified string.
 *
 * @param string The string to set
 * @param path The path to store the string at
 */
- (void)setString: (OFString*)string
	  forPath: (OFString*)path;

/*!
 * @brief Sets the specified path to the specified integer.
 *
 * @param integer The integer to set
 * @param path The path to store the integer at
 */
- (void)setInteger: (intmax_t)integer
	   forPath: (OFString*)path;

/*!
 * @brief Sets the specified path to the specified bool.
 *
 * @param bool_ The bool to set
 * @param path The path to store the bool at
 */
- (void)setBool: (bool)bool_
	forPath: (OFString*)path;

/*!
 * @brief Sets the specified path to the specified float.
 *
 * @param float_ The float to set
 * @param path The path to store the float at
 */
- (void)setFloat: (float)float_
	 forPath: (OFString*)path;

/*!
 * @brief Sets the specified path to the specified double.
 *
 * @param double_ The double to set
 * @param path The path to store the double at
 */
- (void)setDouble: (double)double_
	  forPath: (OFString*)path;

/*!
 * @brief Sets the specified path to the specified array of strings.
 *
 * @param array The array of strings to set
 * @param path The path to store the array of strings at
 */
- (void)setArray: (OFArray OF_GENERIC(OFString*)*)array
	 forPath: (OFString*)path;

/*!
 * @brief Returns the string for the specified path, or nil if the path does
 *	  not exist.
 *
 * @param path The path for which the string value should be returned
 * @return The string value of the specified path
 */
- (OFString*)stringForPath: (OFString*)path;

/*!
 * @brief Returns the string for the specified path, or the default value if
 *	  the path does not exist.
 *
 * @param path The path for which the string value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The string value of the specified path
 */
- (OFString*)stringForPath: (OFString*)path
	      defaultValue: (OFString*)defaultValue;

/*!
 * @brief Returns the integer for the specified path, or the default value if
 *	  the path does not exist.
 *
 * @param path The path for which the integer value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The integer value of the specified path
 */
- (intmax_t)integerForPath: (OFString*)path
	      defaultValue: (intmax_t)defaultValue;

/*!
 * @brief Returns the bool for the specified path, or the default value if the
 *	  path does not exist.
 *
 * @param path The path for which the bool value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The bool value of the specified path
 */
- (bool)boolForPath: (OFString*)path
       defaultValue: (bool)defaultValue;

/*!
 * @brief Returns the float for the specified path, or the default value if the
 *	  path does not exist.
 *
 * @param path The path for which the float value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The float value of the specified path
 */
- (float)floatForPath: (OFString*)path
	 defaultValue: (float)defaultValue;

/*!
 * @brief Returns the double for the specified path, or the default value if
 *	  the path does not exist.
 *
 * @param path The path for which the double value should be returned
 * @param defaultValue The default value to return if the path does not exist
 * @return The double value of the specified path
 */
- (double)doubleForPath: (OFString*)path
	   defaultValue: (double)defaultValue;

/*!
 * @brief Returns the array of strings for the specified path, or an empty
 *	  array if the path does not exist.
 *
 * @param path The path for which the array of strings should be returned
 * @return The array of strings of the specified path
 */
- (OFArray OF_GENERIC(OFString*)*)arrayForPath: (OFString*)path;

/*!
 * @brief Removes the value for the specified path.
 *
 * @param path The path for which the value should be removed
 */
- (void)removeValueForPath: (OFString*)path;

/*!
 * @brief Saves the settings to disk.
 *
 * @warning Some backends might save the settings instantly, others might not
 *	    save them before calling this method for performance reasons. You
 *	    should always call this method after doing a bunch of changes, no
 *	    matter which backend is used!
 */
- (void)save;
@end
