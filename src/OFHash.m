/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFHash.h"

#import "OFNotImplementedException.h"

@implementation OFHash
+ (size_t)digestSize
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

+ (size_t)blockSize
{
	@throw [OFNotImplementedException exceptionWithClass: self
						    selector: _cmd];
}

- (void)updateWithBuffer: (const char*)buffer
		  length: (size_t)length
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (uint8_t*)digest
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (BOOL)isCalculated
{
	return calculated;
}
@end
