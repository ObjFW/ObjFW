/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFColor.h"
#import "OFOnce.h"

#import "OFInvalidArgumentException.h"

@implementation OFColor
#define PREDEFINED_COLOR(name, redValue, greenValue, blueValue)		   \
	static OFColor *name##Color = nil;				   \
									   \
	static void							   \
	initPredefinedColor_##name(void)				   \
	{								   \
		name##Color = [[OFColor alloc] initWithRed: redValue	   \
						     green: greenValue	   \
						      blue: blueValue	   \
						     alpha: 1];		   \
	}								   \
									   \
	+ (OFColor *)name						   \
	{								   \
		static OFOnceControl onceControl = OFOnceControlInitValue; \
		OFOnce(&onceControl, initPredefinedColor_##name);	   \
									   \
		return name##Color;					   \
	}

PREDEFINED_COLOR(black,   0.00f, 0.00f, 0.00f)
PREDEFINED_COLOR(silver,  0.75f, 0.75f, 0.75f)
PREDEFINED_COLOR(grey,    0.50f, 0.50f, 0.50f)
PREDEFINED_COLOR(white,   1.00f, 1.00f, 1.00f)
PREDEFINED_COLOR(maroon,  0.50f, 0.00f, 0.00f)
PREDEFINED_COLOR(red,     1.00f, 0.00f, 0.00f)
PREDEFINED_COLOR(purple,  0.50f, 0.00f, 0.50f)
PREDEFINED_COLOR(fuchsia, 1.00f, 0.00f, 1.00f)
PREDEFINED_COLOR(green,   0.00f, 0.50f, 0.00f)
PREDEFINED_COLOR(lime,    0.00f, 1.00f, 0.00f)
PREDEFINED_COLOR(olive,   0.50f, 0.50f, 0.00f)
PREDEFINED_COLOR(yellow,  1.00f, 1.00f, 0.00f)
PREDEFINED_COLOR(navy,    0.00f, 0.00f, 0.50f)
PREDEFINED_COLOR(blue,    0.00f, 0.00f, 1.00f)
PREDEFINED_COLOR(teal,    0.00f, 0.50f, 0.50f)
PREDEFINED_COLOR(aqua,    0.00f, 1.00f, 1.00f)

+ (instancetype)colorWithRed: (float)red
		       green: (float)green
			blue: (float)blue
		       alpha: (float)alpha
{
	return [[[self alloc] initWithRed: red
				    green: green
				     blue: blue
				    alpha: alpha] autorelease];
}

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

- (bool)isEqual: (id)object
{
	OFColor *other;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFColor class]])
		return false;

	other = object;

	if (other->_red != _red)
		return false;
	if (other->_green != _green)
		return false;
	if (other->_blue != _blue)
		return false;
	if (other->_alpha != _alpha)
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;
	float tmp;

	OFHashInit(&hash);

	tmp = OFToLittleEndianFloat(_red);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAdd(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(_green);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAdd(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(_blue);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAdd(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(_alpha);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAdd(&hash, ((char *)&tmp)[i]);

	OFHashFinalize(&hash);

	return hash;
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
