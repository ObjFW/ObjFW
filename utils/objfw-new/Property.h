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
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@interface Property: OFObject
{
	OFString *_name, *_type;
	OFArray OF_GENERIC(OFString *) *_attributes;
}

+ (instancetype)propertyWithString: (OFString *)string;
- (instancetype)initWithString: (OFString *)string;

@property (readonly, nonatomic) OFString *name;
@property (readonly, nonatomic) OFString *type;
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *attributes;
@end

OF_ASSUME_NONNULL_END
