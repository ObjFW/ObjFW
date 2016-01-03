/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include "config.h"

#import "OFReadFailedException.h"
#import "OFString.h"

@implementation OFReadFailedException
- (OFString*)description
{
	if (_errNo != 0)
		return [OFString stringWithFormat:
		    @"Failed to read %zu bytes from an object of type %@: %@",
		    _requestedLength, [_object class], of_strerror(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to read %zu bytes from an object of type %@!",
		    _requestedLength, [_object class]];
}
@end
