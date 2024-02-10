/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@interface OTAssertionFailedException: OFException
{
	OFString *_condition;
	OFString *_Nullable _message;
}

@property (readonly, nonatomic) OFString *condition;
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *message;

+ (instancetype)exceptionWithCondition: (OFString *)condition
			       message: (nullable OFString *)message;
+ (instancetype)exception OF_UNAVAILABLE;
- (instancetype)initWithCondition: (OFString *)condition
			  message: (nullable OFString *)message;
- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
