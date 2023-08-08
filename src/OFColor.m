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

#include <math.h>

#import "OFColor.h"
#import "OFOnce.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@interface OFColor ()
+ (instancetype)of_alloc;
@end

@interface OFColorSingleton: OFColor
@end

@interface OFColorPlaceholder: OFColorSingleton
@end

#ifdef OF_OBJFW_RUNTIME
@interface OFTaggedPointerColor: OFColorSingleton
@end

static const float allowedImprecision = 0.0000001;
#endif

static struct {
	Class isa;
} placeholder;

#ifdef OF_OBJFW_RUNTIME
static int colorTag;
#endif

@implementation OFColorSingleton
- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OFMaxRetainCount;
}
@end

@implementation OFColorPlaceholder
- (instancetype)initWithRed: (float)red
		      green: (float)green
		       blue: (float)blue
		      alpha: (float)alpha
{
#ifdef OF_OBJFW_RUNTIME
	uint8_t redInt = nearbyintf(red * 255);
	uint8_t greenInt = nearbyintf(green * 255);
	uint8_t blueInt = nearbyintf(blue * 255);

	if (fabsf(red * 255 - redInt) < allowedImprecision &&
	    fabsf(green * 255 - greenInt) < allowedImprecision &&
	    fabsf(blue * 255 - blueInt) < allowedImprecision && alpha == 1) {
		id ret = objc_createTaggedPointer(colorTag,
		    (uintptr_t)redInt << 16 | (uintptr_t)greenInt << 8 |
		    (uintptr_t)blueInt);

		if (ret != nil)
			return ret;
	}
#endif

	return (id)[[OFColor of_alloc] initWithRed: red
					     green: green
					      blue: blue
					     alpha: alpha];
}
@end

#ifdef OF_OBJFW_RUNTIME
@implementation OFTaggedPointerColor
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
@end
#endif

@implementation OFColor
+ (void)initialize
{
	if (self != [OFColor class])
		return;

	object_setClass((id)&placeholder, [OFColorPlaceholder class]);
#ifdef OF_OBJFW_RUNTIME
	colorTag =
	    objc_registerTaggedPointerClass([OFTaggedPointerColor class]);
#endif
}

+ (instancetype)of_alloc
{
	return [super alloc];
}

+ (instancetype)alloc
{
	if (self == [OFColor class])
		return (id)&placeholder;

	return [super alloc];
}

#define PREDEFINED_COLOR(name, redValue, greenValue, blueValue)		   \
	static OFColor *name##Color = nil;				   \
									   \
	static void							   \
	initPredefinedColor_##name(void)				   \
	{								   \
		name##Color = [[OFColorSingleton alloc]			   \
		    initWithRed: redValue				   \
			  green: greenValue				   \
			   blue: blueValue				   \
			  alpha: 1];					   \
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
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(_green);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(_blue);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

	tmp = OFToLittleEndianFloat(_alpha);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OFHashAddByte(&hash, ((char *)&tmp)[i]);

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

- (OFString *)description
{
	float red, green, blue, alpha;

	[self getRed: &red green: &green blue: &blue alpha: &alpha];

	return [OFString stringWithFormat:
	    @"<%@ red=%f green=%f blue=%f alpha=%f>",
	    self.class, red, green, blue, alpha];
}
@end
