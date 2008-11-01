/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFArray.h"

#import "OFExceptions.h"
#import "OFMacros.h"

@implementation OFArray
- initWithItemSize: (size_t)is
{
	if ((self = [super init])) {
		data = NULL;
		itemsize = is;
		size = 0;
	}

	return self;
}

- (size_t)size
{
	return size;
}

- (size_t)itemsize
{
	return itemsize;
}

- (void*)item: (size_t)item
{
	/* FIXME */
	OF_NOT_IMPLEMENTED(NULL)
}

- (void*)last
{
	/* FIXME */
	OF_NOT_IMPLEMENTED(NULL)
}

- add: (void*)item
{
	return [self addNItems: 1
		    fromCArray: item];
}

- addNItems: (size_t)nitems
 fromCArray: (void*)carray
{
	/* FIXME */
	OF_NOT_IMPLEMENTED(self)
}

- removeLastNItems: (size_t)nitems
{
	/* FIXME */
	OF_NOT_IMPLEMENTED(self)
}
@end

@implementation OFBigArray
- initWithSize: (size_t)is
{
	if ((self = [super init]))
		realsize = 0;

	return self;
}

- addNItems: (size_t)nitems
 fromCArray: (void*)carray
{
	/* FIXME */
	OF_NOT_IMPLEMENTED(self)
}

- removeLastNItems: (size_t)nitems
{
	/* FIXME */
	OF_NOT_IMPLEMENTED(self)
}
@end
