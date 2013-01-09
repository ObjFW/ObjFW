/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "runtime.h"

#import "OFObject.h"
#import "OFBlock.h"

id
objc_retain(id object)
{
	return [object retain];
}

id
objc_retainBlock(id block)
{
	return (id)_Block_copy(block);
}

id
objc_retainAutorelease(id object)
{
	return [[object retain] autorelease];
}

void
objc_release(id object)
{
	[object release];
}

id
objc_autorelease(id object)
{
	return [object autorelease];
}

id
objc_autoreleaseReturnValue(id object)
{
	return objc_autorelease(object);
}

id
objc_retainAutoreleaseReturnValue(id object)
{
	return objc_autoreleaseReturnValue(objc_retain(object));
}

id
objc_retainAutoreleasedReturnValue(id object)
{
	return objc_retain(object);
}

id
objc_storeStrong(id *object, id value)
{
	id old = *object;
	*object = objc_retain(value);
	objc_release(old);

	return value;
}
