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

#include "config.h"

#import "OFTaggedPointerColor.h"

static int colorTag;

@implementation OFTaggedPointerColor
+ (void)initialize
{
	if (self == [OFTaggedPointerColor class])
		colorTag = objc_registerTaggedPointerClass(self);
}

+ (OFTaggedPointerColor *)colorWithRed: (uint8_t)red
				 green: (uint8_t)green
				  blue: (uint8_t)blue
{
	return objc_createTaggedPointer(colorTag,
	    (uintptr_t)red << 16 | (uintptr_t)green << 8 | (uintptr_t)blue);
}

- (void)getRed: (float *)red
	 green: (float *)green
	  blue: (float *)blue
	 alpha: (float *)alpha
{
	uintptr_t value = object_getTaggedPointerValue(self);

	*red = (float)(value >> 16) / 255;
	*green = (float)((value >> 8) & 0xFF) / 255;
	*blue = (float)(value & 0xFF) / 255;

	if (alpha != NULL)
		*alpha = 1;
}

OF_SINGLETON_METHODS
@end
