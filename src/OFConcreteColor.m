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

#include "config.h"

#import "OFConcreteColor.h"

#import "OFInvalidArgumentException.h"

@implementation OFConcreteColor
- (instancetype)initWithRed: (float)red
		      green: (float)green
		       blue: (float)blue
		      alpha: (float)alpha
{
	self = [super init];

	@try {
		if (red < 0.0 || red > 1.0 ||
		    green < 0.0 || green > 1.0 ||
		    blue < 0.0 || blue > 1.0 ||
		    alpha < 0.0 || alpha > 1.0)
			@throw [OFInvalidArgumentException exception];

		_red = red;
		_green = green;
		_blue = blue;
		_alpha = alpha;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
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
@end

