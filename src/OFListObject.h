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

@interface OFListObject: OFObject
{
	void	     *data;
	OFListObject *next;
	OFListObject *prev;
}

+ newWithData: (void*)ptr;
- initWithData: (void*)ptr;
- freeIncludingData;
- (void*)data;
- (OFListObject*)next;
- (OFListObject*)prev;
- (void)setNext: (OFListObject*)ptr;
- (void)setPrev: (OFListObject*)ptr;
@end
