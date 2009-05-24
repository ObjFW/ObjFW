/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFConstString.h"

#ifndef __objc_INCLUDE_GNU
void *_OFConstStringClassReference;
#endif

@implementation OFConstString
#ifndef __objc_INCLUDE_GNU
+ (void)load
{
	objc_setFutureClass((Class)&_OFConstStringClassReference,
	    "OFConstString");
}
#endif

- retain
{
	return self;
}

- (void)release
{
}

- (size_t)retainCount
{
	return 1;
}

- autorelease
{
	return self;
}
@end
