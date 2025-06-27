/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import <Foundation/NSString.h>

#import "OFString+NSObject.h"

#import "OFInitializationFailedException.h"

int _OFString_NSObject_reference;

@implementation OFString (NSObject)
- (NSString *)NSObject
{
	NSString *string = [NSString stringWithUTF8String: self.UTF8String];

	if (string == nil)
		@throw [OFInitializationFailedException
		    exceptionWithClass: [NSString class]];

	return string;
}
@end
