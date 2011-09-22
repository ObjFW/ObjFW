/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFEnumerator.h"

#import "OFNotImplementedException.h"

@implementation OFEnumerator
- init
{
	if (isa == [OFEnumerator class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	return [super init];
}

- (id)nextObject
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)reset
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}
@end
