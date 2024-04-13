/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFFileManager.h"
#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFData;
@class OFDate;
@class OFIRI;
@class OFStream;

/**
 * @class OFIRIHandler OFIRIHandler.h ObjFW/OFIRIHandler.h
 *
 * @brief A handler for an IRI scheme.
 */
@interface OFIRIHandler: OFObject
{
	OFString *_scheme;
	OF_RESERVE_IVARS(OFIRIHandler, 4)
}

/**
 * @brief The scheme this OFIRIHandler handles.
 */
@property (readonly, nonatomic) OFString *scheme;

/**
 * @brief Registers the specified class as the handler for the specified scheme.
 *
 * If the same class is specified for two schemes, one instance of it is
 * created per scheme.
 *
 * @param class_ The class to register as the handler for the specified scheme
 * @param scheme The scheme for which to register the handler
 * @return Whether the class was successfully registered. If a handler for the
 *	   same scheme is already registered, registration fails.
 */
+ (bool)registerClass: (Class)class_ forScheme: (OFString *)scheme;

/**
 * @brief Returns the handler for the specified IRI.
 *
 * @return The handler for the specified IRI.
 * @throw OFUnsupportedProtocolException The specified IRI is not supported
 */
+ (OFIRIHandler *)handlerForIRI: (OFIRI *)IRI;

/**
 * @brief Opens the item at the specified IRI.
 *
 * @param IRI The IRI of the item which should be opened
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       @n
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | Read-only
 *	       `r+`           | Read-write
 *	       `w`            | Write-only, create or truncate
 *	       `wx`           | Write-only, create or fail, exclusive
 *	       `w+`           | Read-write, create or truncate
 *	       `w+x`          | Read-write, create or fail, exclusive
 *	       `a`            | Write-only, create or append
 *	       `a+`           | Read-write, create or append
 *	       @n
 *	       The handler is allowed to not implement all modes and is also
 *	       allowed to implement additional, scheme-specific modes.
 * @return The opened stream if it was successfully opened
 * @throw OFOpenItemFailedException Opening the item failed
 * @throw OFUnsupportedProtocolException The specified IRI is not supported
 */
+ (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes the handler for the specified scheme.
 *
 * @param scheme The scheme to initialize for
 * @return An initialized IRI handler
 */
- (instancetype)initWithScheme: (OFString *)scheme OF_DESIGNATED_INITIALIZER;

/**
 * @brief Opens the item at the specified IRI.
 *
 * @param IRI The IRI of the item which should be opened
 * @param mode The mode in which the file should be opened.@n
 *	       Possible modes are:
 *	       @n
 *	       Mode           | Description
 *	       ---------------|-------------------------------------
 *	       `r`            | Read-only
 *	       `r+`           | Read-write
 *	       `w`            | Write-only, create or truncate
 *	       `wx`           | Write-only, create or fail, exclusive
 *	       `w+`           | Read-write, create or truncate
 *	       `w+x`          | Read-write, create or fail, exclusive
 *	       `a`            | Write-only, create or append
 *	       `a+`           | Read-write, create or append
 *	       @n
 *	       The handler is allowed to not implement all modes and is also
 *	       allowed to implement additional, scheme-specific modes.
 * @return The opened stream if it was successfully opened
 * @throw OFOpenItemFailedException Opening the item failed
 * @throw OFUnsupportedProtocolException The specified IRI is not supported by
 *					 the handler
 */
- (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode;

/**
 * @brief Returns the attributes for the item at the specified IRI.
 *
 * @param IRI The IRI to return the attributes for
 * @return A dictionary of attributes for the specified IRI, with the keys of
 *	   type @ref OFFileAttributeKey
 * @throw OFGetItemAttributesFailedException Failed to get the attributes of
 *					     the item
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (OFFileAttributes)attributesOfItemAtIRI: (OFIRI *)IRI;

/**
 * @brief Sets the attributes for the item at the specified IRI.
 *
 * All attributes not part of the dictionary are left unchanged.
 *
 * @param attributes The attributes to set for the specified IRI
 * @param IRI The IRI of the item to set the attributes for
 * @@throw OFSetItemAttributesFailedException Failed to set the attributes of
 *					      the item
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 * @throw OFNotImplementedException Setting one or more of the specified
 *				    attributes is not implemented for the
 *				    specified item
 */
- (void)setAttributes: (OFFileAttributes)attributes ofItemAtIRI: (OFIRI *)IRI;

/**
 * @brief Checks whether a file exists at the specified IRI.
 *
 * @param IRI The IRI to check
 * @return A boolean whether there is a file at the specified IRI
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (bool)fileExistsAtIRI: (OFIRI *)IRI;

/**
 * @brief Checks whether a directory exists at the specified IRI.
 *
 * @param IRI The IRI to check
 * @return A boolean whether there is a directory at the specified IRI
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (bool)directoryExistsAtIRI: (OFIRI *)IRI;

/**
 * @brief Creates a directory at the specified IRI.
 *
 * @param IRI The IRI of the directory to create
 * @throw OFCreateDirectoryFailedException Creating the directory failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (void)createDirectoryAtIRI: (OFIRI *)IRI;

/**
 * @brief Returns an array with the IRIs of the items in the specified
 *	  directory.
 *
 * @note `.` and `..` are not part of the returned array.
 *
 * @param IRI The IRI to the directory whose items should be returned
 * @return An array with the IRIs of the items in the specified directory
 * @throw OFOpenItemFailedException Opening the directory failed
 * @throw OFReadFailedException Reading from the directory failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (OFArray OF_GENERIC(OFIRI *) *)contentsOfDirectoryAtIRI: (OFIRI *)IRI;

/**
 * @brief Removes the item at the specified IRI.
 *
 * If the item at the specified IRI is a directory, it is removed recursively.
 *
 * @param IRI The IRI to the item which should be removed
 * @throw OFRemoveItemFailedException Removing the item failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (void)removeItemAtIRI: (OFIRI *)IRI;

/**
 * @brief Creates a hard link for the specified item.
 *
 * The destination IRI must have a full path, which means it must include the
 * name of the item.
 *
 * This method is not available for all IRIs.
 *
 * @param source The IRI to the item for which a link should be created
 * @param destination The IRI to the item which should link to the source
 * @throw OFLinkItemFailedException Linking the item failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the scheme
 *					 of one of the IRIs
 * @throw OFNotImplementedException Hardlinks are not implemented for the
 *				    specified IRI
 */
- (void)linkItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination;

/**
 * @brief Creates a symbolic link for an item.
 *
 * The destination IRI must have a full path, which means it must include the
 * name of the item.
 *
 * This method is not available for all IRIs.
 *
 * @note On Windows, this requires at least Windows Vista and administrator
 *	 privileges!
 *
 * @param IRI The IRI to the item which should symbolically link to the target
 * @param target The target of the symbolic link
 * @throw OFCreateSymbolicLinkFailed Creating a symbolic link failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (void)createSymbolicLinkAtIRI: (OFIRI *)IRI
	    withDestinationPath: (OFString *)target;

/**
 * @brief Tries to efficiently copy an item. If a copy would only be possible
 *	  by reading the entire item and then writing it, it returns false.
 *
 * The destination IRI must have a full path, which means it must include the
 * name of the item.
 *
 * If an item already exists, the copy operation fails. This is also the case
 * if a directory is copied and an item already exists in the destination
 * directory.
 *
 * @param source The file, directory or symbolic link to copy
 * @param destination The destination IRI
 * @return True if an efficient copy was performed, false if an efficient copy
 *	   was not possible. Note that errors while performing a copy are
 *	   reported via exceptions and not by returning false!
 * @throw OFCopyItemFailedException Copying failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (bool)copyItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination;

/**
 * @brief Tries to efficiently move an item. If a move would only be possible
 *	  by copying the source and deleting it, it returns false.
 *
 * The destination IRI must have a full path, which means it must include the
 * name of the item.
 *
 * If the destination is on a different logical device or uses a different
 * scheme, an efficient move is not possible and false is returned.
 *
 * @param source The item to rename
 * @param destination The new name for the item
 * @return True if an efficient move was performed, false if an efficient move
 *	   was not possible. Note that errors while performing a move are
 *	   reported via exceptions and not by returning false!
 * @throw OFMoveItemFailedException Moving failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 */
- (bool)moveItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination;

/**
 * @brief Returns the extended attribute data for the specified name of the
 *	  item at the specified IRI.
 *
 * @deprecated Use @ref getExtendedAttributeData:andType:forName:ofItemAtIRI:
 *	       instead.
 *
 * This method is not available for all IRIs.
 *
 * @param name The name of the extended attribute
 * @param IRI The IRI of the item to return the extended attribute from
 * @return The extended attribute data for the specified name of the item at
 *	   the specified IRI
 * @throw OFGetItemAttributesFailedException Getting the extended attribute
 *					     failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 * @throw OFNotImplementedException Getting extended attributes is not
 *				    implemented for the specified item
 */
- (OFData *)extendedAttributeDataForName: (OFString *)name
			     ofItemAtIRI: (OFIRI *)IRI
    OF_DEPRECATED(ObjFW, 1, 1,
    "Use -[getExtendedAttributeData:andType:forName:ofItemAtIRI:] instead");

/**
 * @brief Gets the extended attribute data and type for the specified name
 *	  of the item at the specified IRI.
 *
 * This method is not available for all IRIs.
 *
 * @param data A pointer to `OFData *` that gets set to the data of the
 *	       extended attribute
 * @param type A pointer to `id` that gets set to the type of the extended
 *	       attribute, if not `NULL`. Gets set to `nil` if the extended
 *	       attribute has no type. The type of the type depends on the IRI
 *	       handler.
 * @param name The name of the extended attribute
 * @param IRI The IRI of the item to return the extended attribute from
 * @throw OFGetItemAttributesFailedException Getting the extended attribute
 *					     failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 * @throw OFNotImplementedException Getting extended attributes is not
 *				    implemented for the specified item
 */
- (void)getExtendedAttributeData: (OFData *_Nonnull *_Nonnull)data
			 andType: (id _Nullable *_Nullable)type
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI;

/**
 * @brief Sets the extended attribute data for the specified name of the item
 *	  at the specified IRI.
 *
 * @deprecated Use @ref setExtendedAttributeData:andType:forName:ofItemAtIRI:
 *	       instead.
 *
 * This method is not available for all IRIs.
 *
 * @param data The data for the extended attribute
 * @param name The name of the extended attribute
 * @param IRI The IRI of the item to set the extended attribute on
 * @throw OFSetItemAttributesFailedException Setting the extended attribute
 *					     failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 * @throw OFNotImplementedException Setting extended attributes is not
 *				    implemented for the specified item
 */
- (void)setExtendedAttributeData: (OFData *)data
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI
    OF_DEPRECATED(ObjFW, 1, 1,
    "Use -[setExtendedAttributeData:andType:forName:ofItemAtIRI:] instead");

/**
 * @brief Sets the extended attribute data and type for the specified name of
 *	  the item at the specified IRI.
 *
 * This method is not available for all IRIs.
 * Not all IRIs support a non-nil type.
 *
 * @param data The data for the extended attribute
 * @param type The type for the extended attribute. `nil` does not mean to keep
 *	       the existing type, but to set it to no type. The type of the
 *	       type depends on the IRI handler.
 * @param name The name of the extended attribute
 * @param IRI The IRI of the item to set the extended attribute on
 * @throw OFSetItemAttributesFailedException Setting the extended attribute
 *					     failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 * @throw OFNotImplementedException Setting extended attributes is not
 *				    implemented for the specified item or a
 *				    type was specified and typed extended
 *				    attributes are not supported
 */
- (void)setExtendedAttributeData: (OFData *)data
			 andType: (nullable id)type
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI;

/**
 * @brief Removes the extended attribute for the specified name of the item at
 *	  the specified IRI.
 *
 * This method is not available for all IRIs.
 *
 * @param name The name of the extended attribute to remove
 * @param IRI The IRI of the item to remove the extended attribute from
 * @throw OFSetItemAttributesFailedException Removing the extended attribute
 *					     failed
 * @throw OFUnsupportedProtocolException The handler cannot handle the IRI's
 *					 scheme
 * @throw OFNotImplementedException Removing extended attributes is not
 *				    implemented for the specified item
 */
- (void)removeExtendedAttributeForName: (OFString *)name
			   ofItemAtIRI: (OFIRI *)IRI;
@end

OF_ASSUME_NONNULL_END
