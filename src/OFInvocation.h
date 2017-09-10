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

@class OFMethodSignature;
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableData;

/*!
 * @class OFInvocation OFInvocation.h ObjFW/OFInvocation.h
 *
 * @brief A class for storing and accessing invocations, and invoking them.
 */
@interface OFInvocation: OFObject
{
	OFMethodSignature *_methodSignature;
	OFMutableArray OF_GENERIC(OFMutableData *) *_arguments;
	OFMutableData *_returnValue;
}

/*!
 * The method signature for the invocation.
 */
@property (readonly, nonatomic) OFMethodSignature *methodSignature;

/*!
 * @brief Creates a new invocation with the specified method signature.
 *
 * @param signature The method signature for the invocation
 * @return A new, autoreleased OFInvocation
 */
+ (instancetype)invocationWithMethodSignature: (OFMethodSignature *)signature;

/*!
 * @brief Initializes an already allocated invocation with the specified method
 *	  signature.
 *
 * @param signature The method signature for the invocation
 * @return An initialized OFInvocation
 */
- initWithMethodSignature: (OFMethodSignature *)signature;

/*!
 * @brief Sets the argument for the specified index.
 *
 * @param buffer The buffer in which the argument is stored
 * @param index The index of the argument to set
 */
- (void)setArgument: (const void *)buffer
	    atIndex: (size_t)index;

/*!
 * @brief Gets the argument for the specified index.
 *
 * @param buffer The buffer in which the argument is stored
 * @param index The index of the argument to get
 */
- (void)getArgument: (void *)buffer
	    atIndex: (size_t)index;

/*!
 * @brief Sets the return value.
 *
 * @param buffer The buffer in which the return value is stored
 */
- (void)setReturnValue: (const void *)buffer;

/*!
 * @brief Gets the return value.
 *
 * @param buffer The buffer in which the return value is stored
 */
- (void)getReturnValue: (void *)buffer;
@end

OF_ASSUME_NONNULL_END
