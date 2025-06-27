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

#import "OFConcreteDate.h"

@implementation OFConcreteDate
- (instancetype)initWithTimeIntervalSince1970: (OFTimeInterval)seconds
{
	self = [super initWithTimeIntervalSince1970: seconds];

	_seconds = seconds;

	return self;
}

- (OFTimeInterval)timeIntervalSince1970
{
	return _seconds;
}
@end
