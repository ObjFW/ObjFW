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
