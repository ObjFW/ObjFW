/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
