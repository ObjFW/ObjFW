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

#import "OFReadFailedException.h"
#import "OFString.h"

@implementation OFReadFailedException
- (OFString *)description
{
	if (_errNo != 0)
		return [OFString stringWithFormat:
		    @"Failed to read %zu bytes from an object of type %@: %@",
		    _requestedLength, [_object class], OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to read %zu bytes from an object of type %@",
		    _requestedLength, [_object class]];
}
@end
