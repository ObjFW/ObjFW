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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableData;

/**
 * @class OFMethodSignature OFMethodSignature.h ObjFW/OFMethodSignature.h
 *
 * @brief A class for parsing type encodings and accessing them.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMethodSignature: OFObject
{
	char *_types;
	OFMutableData *_typesPointers, *_offsets;
}

/**
 * @brief The number of arguments of the method.
 */
@property (readonly, nonatomic) size_t numberOfArguments;

/**
 * @brief The return type of the method.
 */
@property (readonly, nonatomic) const char *methodReturnType;

/**
 * @brief The size of the arguments on the stack frame.
 *
 * @note This is platform-dependent!
 */
@property (readonly, nonatomic) size_t frameLength;

/**
 * @brief Creates a new OFMethodSignature with the specified ObjC types.
 *
 * @param types The ObjC types of the method
 * @return A new, autoreleased OFMethodSignature
 * @throw OFInvalidFormatException The type encoding is invalid
 */
+ (instancetype)signatureWithObjCTypes: (const char *)types;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFMethodSignature with the specified
 *	  ObjC types.
 *
 * @param types The ObjC types of the method
 * @return An Initialized OFMethodSignature
 * @throw OFInvalidFormatException The type encoding is invalid
 */
- (instancetype)initWithObjCTypes: (const char *)types
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Returns the ObjC type for the argument at the specified index.
 *
 * @param index The index of the argument for which to return the ObjC type
 * @return The ObjC type for the argument at the specified index
 */
- (const char *)argumentTypeAtIndex: (size_t)index;

/**
 * @brief Returns the offset on the stack frame of the argument at the
 *	  specified index.
 *
 * @note This is platform-dependent!
 *
 * @param index The index of the argument for which to return the offset
 * @return The offset on the stack frame of the argument at the specified index
 */
- (size_t)argumentOffsetAtIndex: (size_t)index;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Returns the size for the specified type encoding.
 *
 * @param type The type encoding to return the size for
 * @return The size for the specified type encoding
 * @throw OFInvalidFormatException The type encoding is invalid
 */
extern size_t OFSizeOfTypeEncoding(const char *type);

/**
 * @brief Returns the alignment for the specified type encoding.
 *
 * @param type The type encoding to return the alignment for
 * @return The alignment for the specified type encoding
 * @throw OFInvalidFormatException The type encoding is invalid
 */
extern size_t OFAlignmentOfTypeEncoding(const char *type);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
