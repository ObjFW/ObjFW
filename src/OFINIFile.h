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
#import "OFString.h"
#import "OFINICategory.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableArray OF_GENERIC(ObjectType);

/*!
 * @class OFINIFile OFINIFile.h ObjFW/OFINIFile.h
 *
 * @brief A class for reading, creating and modifying INI files.
 */
@interface OFINIFile: OFObject
{
	OFMutableArray OF_GENERIC(OFINICategory*) *_categories;
}

/*!
 * @brief Creates a new OFINIFile with the contents of the specified file.
 *
 * @param path The path to the file whose contents the OFINIFile should contain
 *
 * @return A new, autoreleased OFINIFile with the contents of the specified file
 */
+ (instancetype)fileWithPath: (OFString*)path;

/*!
 * @brief Creates a new OFINIFile with the contents of the specified file in
 *	  the specified encoding.
 *
 * @param path The path to the file whose contents the OFINIFile should contain
 * @param encoding The encoding of the specified file
 *
 * @return A new, autoreleased OFINIFile with the contents of the specified file
 */
+ (instancetype)fileWithPath: (OFString*)path
		    encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Initializes an already allocated OFINIFile with the contents of the
 *	  specified file.
 *
 * @param path The path to the file whose contents the OFINIFile should contain
 *
 * @return An initialized OFINIFile with the contents of the specified file
 */
- initWithPath: (OFString*)path;

/*!
 * @brief Initializes an already allocated OFINIFile with the contents of the
 *	  specified file in the specified encoding.
 *
 * @param path The path to the file whose contents the OFINIFile should contain
 * @param encoding The encoding of the specified file
 *
 * @return An initialized OFINIFile with the contents of the specified file
 */
- initWithPath: (OFString*)path
      encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Returns an @ref OFINICategory for the category with the specified
 *	  name.
 *
 * @param name The name of the category for which an @ref OFINICategory should
 *	       be returned
 *
 * @return An @ref OFINICategory for the category with the specified name
 */
- (OFINICategory*)categoryForName: (OFString*)name;

/*!
 * @brief Writes the contents of the OFINIFile to a file.
 *
 * @param path The path of the file to write to
 */
- (void)writeToFile: (OFString*)path;

/*!
 * @brief Writes the contents of the OFINIFile to a file in the specified
 *	  encoding.
 *
 * @param path The path of the file to write to
 * @param encoding The encoding to use
 */
- (void)writeToFile: (OFString*)path
	   encoding: (of_string_encoding_t)encoding;
@end

OF_ASSUME_NONNULL_END
