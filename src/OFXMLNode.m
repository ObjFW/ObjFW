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

#include "config.h"

#import "OFXMLNode.h"
#import "OFString.h"

@implementation OFXMLNode
- (instancetype)of_init
{
	return [super init];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFString *)stringValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setStringValue: (OFString *)stringValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (long long)longLongValue
{
	return self.stringValue.longLongValue;
}

- (long long)longLongValueWithBase: (unsigned char)base
{
	return [self.stringValue longLongValueWithBase: base];
}

- (unsigned long long)unsignedLongLongValue
{
	return self.stringValue.unsignedLongLongValue;
}

- (unsigned long long)unsignedLongLongValueWithBase: (unsigned char)base
{
	return [self.stringValue unsignedLongLongValueWithBase: base];
}

- (float)floatValue
{
	return self.stringValue.floatValue;
}

- (double)doubleValue
{
	return self.stringValue.doubleValue;
}

- (OFString *)XMLString
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
	return self.XMLString;
}

- (id)copy
{
	return objc_retain(self);
}
@end
