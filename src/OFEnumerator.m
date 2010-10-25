/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFEnumerator.h"
#import "OFExceptions.h"

@implementation OFEnumerator
- init
{
	if (isa == [OFEnumerator class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException newWithClass: c
						      selector: _cmd];
	}

	return [super init];
}

- (id)nextObject
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)reset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
