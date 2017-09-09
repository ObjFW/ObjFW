/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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
	OFMutableData *_typesPointers;
}

/*!
 * The number of arguments of the method.
 */
@property (readonly, nonatomic) size_t numberOfArguments;

/*!
 * The return type of the method.
 */
@property (readonly, nonatomic) const char *methodReturnType;

/*!
 * @brief Creates a new, autoreleased OFMethodSignature with the specified
 *	  ObjC types.
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
- initWithObjCTypes: (const char *)types;

/*!
 * @brief Returns the ObjC type for the argument at the specified index.
 *
 * @param index The index for which to return the ObjC type
 * @return The ObjC type for the argument at the specified index
 */
- (const char *)argumentTypeAtIndex: (size_t)index;
@end

OF_ASSUME_NONNULL_END
