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
