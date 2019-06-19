/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "NSNumber+OFObject.h"
#import "OFNumber.h"

#import "OFInvalidArgumentException.h"

int _NSNumber_OFObject_reference;

@implementation NSNumber (OFObject)
- (id)OFObject
{
	const char *type = self.objCType;

	if (strcmp(type, "c") == 0)
		return [OFNumber numberWithChar: self.charValue];
	else if (strcmp(type, "C") == 0)
		return [OFNumber numberWithUnsignedChar:
		    self.unsignedCharValue];
	else if (strcmp(type, "s") == 0)
		return [OFNumber numberWithShort: self.shortValue];
	else if (strcmp(type, "S") == 0)
		return [OFNumber numberWithUnsignedShort:
		    self.unsignedShortValue];
	else if (strcmp(type, "i") == 0)
		return [OFNumber numberWithInt: self.intValue];
	else if (strcmp(type, "I") == 0)
		return [OFNumber numberWithUnsignedInt: self.unsignedIntValue];
	else if (strcmp(type, "l") == 0)
		return [OFNumber numberWithLong: self.longValue];
	else if (strcmp(type, "L") == 0)
		return [OFNumber numberWithUnsignedLong:
		    self.unsignedLongValue];
	else if (strcmp(type, "q") == 0)
		return [OFNumber numberWithLongLong: self.longLongValue];
	else if (strcmp(type, "Q") == 0)
		return [OFNumber numberWithUnsignedLongLong:
		    self.unsignedLongLongValue];
	else if (strcmp(type, "f") == 0)
		return [OFNumber numberWithFloat: self.floatValue];
	else if (strcmp(type, "d") == 0)
		return [OFNumber numberWithDouble: self.doubleValue];

	@throw [OFInvalidArgumentException exception];
}
@end
