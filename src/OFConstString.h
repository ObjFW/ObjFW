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

#import "OFObject.h"

#ifndef __objc_INCLUDE_GNU
extern void *_OFConstStringClassReference;
#endif

/**
 * A class for storing static strings using the @"" literal.
 */
@interface OFConstString: Object <OFHashable, OFRetainRelease>
{
	char   *string;
	size_t length;
}

/**
 * \return The OFString as a C string
 */
- (const char*)cString;

/**
 * \return The length of the OFString
 */
- (size_t)length;

/**
 * Compares the OFString to another object.
 *
 * \param obj An object to compare with
 * \return An integer which is the result of the comparison, see for example
 *	   strcmp
 */
- (int)compare: (id)obj;
@end
