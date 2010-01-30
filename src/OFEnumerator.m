/*
 * Copyright (c) 2008 - 2009
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
	if (isa == [OFEnumerator class])
		@throw [OFNotImplementedException newWithClass: isa
						      selector: _cmd];

	return [super init];
}

- (id)nextObject
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- reset
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
