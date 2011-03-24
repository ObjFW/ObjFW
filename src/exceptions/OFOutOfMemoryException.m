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

#import "OFOutOfMemoryException.h"
#import "OFString.h"

@implementation OFOutOfMemoryException
+  newWithClass: (Class)class_
  requestedSize: (size_t)size
{
	return [[self alloc] initWithClass: class_
			     requestedSize: size];
}

- initWithClass: (Class)class_
  requestedSize: (size_t)size
{
	self = [super initWithClass: class_];

	requestedSize = size;

	return self;
}

- (OFString*)description
{
	if (description != nil)
		return description;

	if (requestedSize)
		description = [[OFString alloc] initWithFormat:
		    @"Could not allocate %zu bytes in class %@!", requestedSize,
		    inClass];
	else
		description = [[OFString alloc] initWithFormat:
		    @"Could not allocate enough memory in class %@!", inClass];

	return description;
}

- (size_t)requestedSize
{
	return requestedSize;
}
@end
