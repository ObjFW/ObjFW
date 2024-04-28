/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import <Foundation/NSValue.h>

#import "OFNumber+NSObject.h"

#import "OFInvalidArgumentException.h"

int _OFNumber_NSObject_reference;

@implementation OFNumber (NSObject)
- (NSNumber *)NSObject
{
	const char *type = self.objCType;

	if (strcmp(type, "B") == 0)
		return [NSNumber numberWithBool: self.boolValue];
	else if (strcmp(type, "c") == 0)
		return [NSNumber numberWithChar: self.charValue];
	else if (strcmp(type, "C") == 0)
		return [NSNumber numberWithUnsignedChar:
		    self.unsignedCharValue];
	else if (strcmp(type, "s") == 0)
		return [NSNumber numberWithShort: self.shortValue];
	else if (strcmp(type, "S") == 0)
		return [NSNumber numberWithUnsignedShort:
		    self.unsignedShortValue];
	else if (strcmp(type, "i") == 0)
		return [NSNumber numberWithInt: self.intValue];
	else if (strcmp(type, "I") == 0)
		return [NSNumber numberWithUnsignedInt: self.unsignedIntValue];
	else if (strcmp(type, "l") == 0)
		return [NSNumber numberWithLong: self.longValue];
	else if (strcmp(type, "L") == 0)
		return [NSNumber numberWithUnsignedLong:
		    self.unsignedLongValue];
	else if (strcmp(type, "q") == 0)
		return [NSNumber numberWithLongLong: self.longLongValue];
	else if (strcmp(type, "Q") == 0)
		return [NSNumber numberWithUnsignedLongLong:
		    self.unsignedLongLongValue];
	else if (strcmp(type, "f") == 0)
		return [NSNumber numberWithFloat: self.floatValue];
	else if (strcmp(type, "d") == 0)
		return [NSNumber numberWithDouble: self.doubleValue];

	@throw [OFInvalidArgumentException exception];
}
@end
