/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

@class OFMutableData;

/*!
 * @class OFMethodSignature OFMethodSignature.h ObjFW/OFMethodSignature.h
 *
 * @brief A class for parsing type encodings and accessing them.
 */
@interface OFMethodSignature: OFObject
{
	char *_types;
	OFMutableData *_typesPointers, *_offsets;
}

/*!
 * @brief The number of arguments of the method.
 */
@property (readonly, nonatomic) size_t numberOfArguments;

/*!
 * @brief The return type of the method.
 */
@property (readonly, nonatomic) const char *methodReturnType;

/*!
 * @brief The size of the arguments on the stack frame.
 *
 * @note This is platform-dependent!
 */
@property (readonly, nonatomic) size_t frameLength;

/*!
 * @brief Creates a new OFMethodSignature with the specified ObjC types.
 *
 * @param types The ObjC types of the method
 * @return A new, autoreleased OFMethodSignature
 */
+ (instancetype)signatureWithObjCTypes: (const char *)types;

/*!
 * @brief Initializes an already allocated OFMethodSignature with the specified
 *	  ObjC types.
 *
 * @param types The ObjC types of the method
 * @return An Initialized OFMethodSignature
 */
- (instancetype)initWithObjCTypes: (const char *)types;

/*!
 * @brief Returns the ObjC type for the argument at the specified index.
 *
 * @param index The index of the argument for which to return the ObjC type
 * @return The ObjC type for the argument at the specified index
 */
- (const char *)argumentTypeAtIndex: (size_t)index;

/*!
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
/*!
 * @brief Returns the size for the specified type encoding.
 *
 * @param type The type encoding to return the size for
 * @return The size for the specified type encoding
 */
extern size_t of_sizeof_type_encoding(const char *type);

/*!
 * @brief Returns the alignment for the specified type encoding.
 *
 * @param type The type encoding to return the alignment for
 * @return The alignment for the specified type encoding
 */
extern size_t of_alignof_type_encoding(const char *type);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
