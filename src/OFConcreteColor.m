/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFConcreteColor.h"

@implementation OFConcreteColor
- (instancetype)initWithRed: (float)red
		      green: (float)green
		       blue: (float)blue
		      alpha: (float)alpha
		 colorSpace: (OFColorSpace *)colorSpace
{
	self = [super init];

	@try {
		_red = red;
		_green = green;
		_blue = blue;
		_alpha = alpha;
		_colorSpace = objc_retain(colorSpace);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_colorSpace);

	[super dealloc];
}

- (void)getRed: (float *)red
	 green: (float *)green
	  blue: (float *)blue
	 alpha: (float *)alpha
{
	*red = _red;
	*green = _green;
	*blue = _blue;

	if (alpha != NULL)
		*alpha = _alpha;
}

- (OFColorSpace *)colorSpace
{
	return _colorSpace;
}
@end
