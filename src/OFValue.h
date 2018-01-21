/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

/*!
 * @class OFValue OFValue.h ObjFW/OFValue.h
 *
 * @brief A class for storing arbitrary values in an object.
 */
@interface OFValue: OFObject
/*!
 * @brief The ObjC type encoding of the value.
 */
@property (nonatomic, readonly) const char *objCType;

/*!
 * @brief Creates a new, autorelease OFValue with the specified bytes of the
 *	  specified type.
 *
 * @param bytes The bytes containing the value
 * @param objCType The ObjC type encoding for the value
 * @return A new, autoreleased OFValue
 */
+ (instancetype)valueWithBytes: (const void *)bytes
		      objCType: (const char *)objCType;

/*!
 * @brief Initializes an already allocated OFValue with the specified bytes of
 *	  the specified type.
 *
 * @param bytes The bytes containing the value
 * @param objCType The ObjC type encoding for the value
 * @return An initialized OFValue
 */
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType;

/*!
 * @brief Gets the value.
 *
 * If the specified size does not match, this raises an
 * @ref OFOutOfRangeException.
 *
 * @param value The buffer to copy the value into
 * @param size The size of the value
 */
- (void)getValue: (void *)value
	    size: (size_t)size;
@end

OF_ASSUME_NONNULL_END

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for array literals to work */
@compatibility_alias NSValue OFValue;
#endif
