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

#import "OFString.h"

@interface OFString_UTF8: OFString
{
@public
	struct of_string_utf8_ivars {
		char	 *cString;
		size_t	 cStringLength;
		BOOL	 UTF8;
		size_t	 length;
		BOOL	 hashed;
		uint32_t hash;
	} *restrict s;
}
@end
