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
#import "OFString.h"
#import "OFINISection.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;
@class OFMutableArray OF_GENERIC(ObjectType);

/**
 * @class OFINIFile OFINIFile.h ObjFW/ObjFW.h
 *
 * @brief A class for reading, creating and modifying INI files.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFINIFile: OFObject
{
	OFMutableArray OF_GENERIC(OFINISection *) *_sections;
}

/**
 * @brief All sections in the INI file.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFINISection *) *sections;

/**
 * @brief All sections in the INI file.
 *
 * @deprecated Use @ref sections instead.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFINISection *) *categories
    OF_DEPRECATED(ObjFW, 1, 2, "Use -[sections] instead");

/**
 * @brief Creates a new OFINIFile with the contents of the specified file.
 *
 * @param IRI The IRI to the file whose contents the OFINIFile should contain
 *
 * @return A new, autoreleased OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
+ (instancetype)fileWithIRI: (OFIRI *)IRI;

/**
 * @brief Creates a new OFINIFile with the contents of the specified file in
 *	  the specified encoding.
 *
 * @param IRI The IRI to the file whose contents the OFINIFile should contain
 * @param encoding The encoding of the specified file
 * @return A new, autoreleased OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
+ (instancetype)fileWithIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFINIFile with the contents of the
 *	  specified file.
 *
 * @param IRI The IRI to the file whose contents the OFINIFile should contain
 *
 * @return An initialized OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
- (instancetype)initWithIRI: (OFIRI *)IRI;

/**
 * @brief Initializes an already allocated OFINIFile with the contents of the
 *	  specified file in the specified encoding.
 *
 * @param IRI The IRI to the file whose contents the OFINIFile should contain
 * @param encoding The encoding of the specified file
 * @return An initialized OFINIFile with the contents of the specified file
 * @throw OFInvalidFormatException The format of the specified INI file is
 *				   invalid
 * @throw OFInvalidEncodingException The INI file is not in the specified
 *				     encoding
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		   encoding: (OFStringEncoding)encoding
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Returns an @ref OFINISection for the section with the specified name.
 *
 * @param name The name of the section for which an @ref OFINISection should be
 *	       returned
 *
 * @return An @ref OFINISection for the section with the specified name
 */
- (OFINISection *)sectionForName: (OFString *)name;

/**
 * @brief Returns an @ref OFINISection for the section with the specified name.
 *
 * @deprecated Use @ref sectionForName: instead.
 *
 * @param name The name of the section for which an @ref OFINISection should be
 *	       returned
 *
 * @return An @ref OFINISection for the section with the specified name
 */
- (OFINISection *)categoryForName: (OFString *)name
    OF_DEPRECATED(ObjFW, 1, 2, "Use -[sectionForName:] instead");

/**
 * @brief Writes the contents of the OFINIFile to a file.
 *
 * @param IRI The IRI of the file to write to
 */
- (void)writeToIRI: (OFIRI *)IRI;

/**
 * @brief Writes the contents of the OFINIFile to a file in the specified
 *	  encoding.
 *
 * @param IRI The IRI of the file to write to
 * @param encoding The encoding to use
 */
- (void)writeToIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding;
@end

OF_ASSUME_NONNULL_END
