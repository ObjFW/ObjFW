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

#include "config.h"

#import "OFColor.h"

#import "OFInvalidArgumentException.h"

@implementation OFColor
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

- (uint32_t)hash
{
	uint32_t hash;
	union {
		float f;
		unsigned char b[sizeof(float)];
	} f;

	OF_HASH_INIT(hash);

	f.f = OF_BSWAP_FLOAT_IF_LE(_red);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OF_HASH_ADD(hash, f.b[i]);

	f.f = OF_BSWAP_FLOAT_IF_LE(_green);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OF_HASH_ADD(hash, f.b[i]);

	f.f = OF_BSWAP_FLOAT_IF_LE(_blue);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OF_HASH_ADD(hash, f.b[i]);

	f.f = OF_BSWAP_FLOAT_IF_LE(_alpha);
	for (uint_fast8_t i = 0; i < sizeof(float); i++)
		OF_HASH_ADD(hash, f.b[i]);

	OF_HASH_FINALIZE(hash);

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
