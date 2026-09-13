/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

@class OFMethodSignature;
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableData;

/**
 * @class OFInvocation OFInvocation.h ObjFW/ObjFW.h
 *
 * @brief A class for storing and accessing invocations, and invoking them.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFInvocation: OFObject
{
	OFMethodSignature *_methodSignature;
	OFMutableArray OF_GENERIC(OFMutableData *) *_arguments;
	OFMutableData *_returnValue;
}

/**
 * @brief The method signature for the invocation.
 */
@property (readonly, nonatomic) OFMethodSignature *methodSignature;

/**
 * @brief Creates a new invocation with the specified method signature.
 *
 * @param signature The method signature for the invocation
 * @return A new, autoreleased OFInvocation
 */
+ (instancetype)invocationWithMethodSignature: (OFMethodSignature *)signature;

/**
 * @brief Initializes an already allocated invocation with the specified method
 *	  signature.
 *
 * @param signature The method signature for the invocation
 * @return An initialized OFInvocation
 */
- (instancetype)initWithMethodSignature: (OFMethodSignature *)signature;

/**
 * @brief Sets the argument for the specified index.
 *
 * @param buffer The buffer in which the argument is stored
 * @param index The index of the argument to set
 */
- (void)setArgument: (const void *)buffer atIndex: (size_t)index;

/**
 * @brief Gets the argument for the specified index.
 *
 * @param buffer The buffer in which the argument is stored
 * @param index The index of the argument to get
 */
- (void)getArgument: (void *)buffer atIndex: (size_t)index;

/**
 * @brief Sets the return value.
 *
 * @param buffer The buffer in which the return value is stored
 */
- (void)setReturnValue: (const void *)buffer;

/**
 * @brief Gets the return value.
 *
 * @param buffer The buffer in which the return value is stored
 */
- (void)getReturnValue: (void *)buffer;
@end

OF_ASSUME_NONNULL_END
