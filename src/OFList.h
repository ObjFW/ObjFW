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
#import "OFListObject.h"

@interface OFList: OFObject
{
	OFListObject *first;
	OFListObject *last;
}

- init;
- free;
- freeWithData;
- (OFListObject*)first;
- (OFListObject*)last;
- (void)add: (OFListObject*)ptr;
- (void)addNew: (void*)ptr;
@end
