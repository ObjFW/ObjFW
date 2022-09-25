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
#import "OFString.h"
#import "OFINICategory.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableArray OF_GENERIC(ObjectType);
@class OFURL;

/**
 * @class OFINIFile OFINIFile.h ObjFW/OFINIFile.h
 *
 * @brief A class for reading, creating and modifying INI files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFINIFile: OFObject
{
	OFMutableArray OF_GENERIC(OFINICategory *) *_categories;
}

/**
 * @brief All categories in the INI file.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFINICategory *) *categories;

/**
 * @brief Creates a new OFINIFile with the contents of the specified file.
 *
 * @param URL The URL to the file whose contents the OFINIFile should contain
 *
 * @return A new, autoreleased OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
+ (instancetype)fileWithURL: (OFURL *)URL;

/**
 * @brief Creates a new OFINIFile with the contents of the specified file in
 *	  the specified encoding.
 *
 * @param URL The URL to the file whose contents the OFINIFile should contain
 * @param encoding The encoding of the specified file
 * @return A new, autoreleased OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
+ (instancetype)fileWithURL: (OFURL *)URL encoding: (OFStringEncoding)encoding;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFINIFile with the contents of the
 *	  specified file.
 *
 * @param URL The URL to the file whose contents the OFINIFile should contain
 *
 * @return An initialized OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
- (instancetype)initWithURL: (OFURL *)URL;

/**
 * @brief Initializes an already allocated OFINIFile with the contents of the
 *	  specified file in the specified encoding.
 *
 * @param URL The URL to the file whose contents the OFINIFile should contain
 * @param encoding The encoding of the specified file
 * @return An initialized OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
- (instancetype)initWithURL: (OFURL *)URL
		   encoding: (OFStringEncoding)encoding
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Returns an @ref OFINICategory for the category with the specified
 *	  name.
 *
 * @param name The name of the category for which an @ref OFINICategory should
 *	       be returned
 *
 * @return An @ref OFINICategory for the category with the specified name
 */
- (OFINICategory *)categoryForName: (OFString *)name;

/**
 * @brief Writes the contents of the OFINIFile to a file.
 *
 * @param URL The URL of the file to write to
 */
- (void)writeToURL: (OFURL *)URL;

/**
 * @brief Writes the contents of the OFINIFile to a file in the specified
 *	  encoding.
 *
 * @param URL The URL of the file to write to
 * @param encoding The encoding to use
 */
- (void)writeToURL: (OFURL *)URL encoding: (OFStringEncoding)encoding;
@end

OF_ASSUME_NONNULL_END
