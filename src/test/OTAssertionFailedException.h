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
