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

#import "OFObject.h"

@interface OFXMLFactory: OFObject
+ (char*)escapeCString: (const char*)s;
+ (char*)createStanza: (const char*)name
	 withCloseTag: (BOOL)close
	      andData: (const char*)data, ...;
+ (char*)concatAndFreeCStrings: (char **)strs;
@end
