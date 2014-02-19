/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
@class OFMutableArray;

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

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *name;
#endif

/*!
 * @brief Sets the name of the INI category.
 *
 * @param name The name to set
 */
- (void)setName: (OFString*)name;

/*!
 * @brief Returns the name of the INI category.
 *
 * @return The name of the INI category
 */
- (OFString*)name;

/*!
 * @brief Returns the string value for the specified key, or nil if it does not
 *	  exist.
 *
 * @param key The key for which the string value should be returned
 * @return The string value for the specified key, or nil if it does not exist
 */
- (OFString*)stringForKey: (OFString*)key;

/*!
 * @brief Returns the string value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * @param key The key for which the string value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The string value for the specified key or the specified default
 *	   value if it does not exist
 */
- (OFString*)stringForKey: (OFString*)key
	     defaultValue: (OFString*)defaultValue;

/*!
 * @brief Returns the integer value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * @param key The key for which the integer value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The integer value for the specified key or the specified default
 *	   value if it does not exist
 */
- (intmax_t)integerForKey: (OFString*)key
	     defaultValue: (intmax_t)defaultValue;

/*!
 * @brief Returns the bool value for the specified key or the specified default
 *	  value if it does not exist.
 *
 * @param key The key for which the bool value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The bool value for the specified key or the specified default value
 *	   if it does not exist
 */
- (bool)boolForKey: (OFString*)key
      defaultValue: (bool)defaultValue;

/*!
 * @brief Returns the float value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * @param key The key for which the float value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The float value for the specified key or the specified default value
 *	   if it does not exist
 */
- (float)floatForKey: (OFString*)key
	defaultValue: (float)defaultValue;

/*!
 * @brief Returns the double value for the specified key or the specified
 *	  default value if it does not exist.
 *
 * @param key The key for which the double value should be returned
 * @param defaultValue The value to return if the key does not exist
 * @return The double value for the specified key or the specified default
 *	   value if it does not exist
 */
- (double)doubleForKey: (OFString*)key
	  defaultValue: (double)defaultValue;

/*!
 * @brief Sets the value of the specified key to the specified string.
 *
 * @param string The string to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setString: (OFString*)string
	   forKey: (OFString*)key;

/*!
 * @brief Sets the value of the specified key to the specified integer.
 *
 * @param integer The integer to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setInteger: (intmax_t)integer
	    forKey: (OFString*)key;

/*!
 * @brief Sets the value of the specified key to the specified bool.
 *
 * @param bool_ The bool to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setBool: (bool)bool_
	 forKey: (OFString*)key;

/*!
 * @brief Sets the value of the specified key to the specified float.
 *
 * @param float_ The float to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setFloat: (float)float_
	  forKey: (OFString*)key;

/*!
 * @brief Sets the value of the specified key to the specified double.
 *
 * @param double_ The double to which the value of the key should be set
 * @param key The key for which the new value should be set
 */
- (void)setDouble: (double)double_
	   forKey: (OFString*)key;

/*!
 * @brief Removes the value for the specified key
 *
 * @param key The key of the value to remove
 */
- (void)removeValueForKey: (OFString*)key;
@end
