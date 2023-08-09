/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

