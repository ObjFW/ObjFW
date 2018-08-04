/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFColor OFColor.h ObjFW/OFColor.h
 *
 * @brief A class for storing a color.
 */
@interface OFColor: OFObject
{
	float _red, _green, _blue, _alpha;
}

/*!
 * @brief Creates a new color with the specified red, green, blue and alpha
 *	  value.
 *
 * @param red The red value of the color, between 0.0 and 1.0
 * @param green The green value of the color, between 0.0 and 1.0
 * @param blue The blue value of the color, between 0.0 and 1.0
 * @param alpha The alpha value of the color, between 0.0 and 1.0
 * @return A new color with the specified red, green, blue and alpha value
 */
+ (instancetype)colorWithRed: (float)red
		       green: (float)green
			blue: (float)blue
		       alpha: (float)alpha;

/*!
 * @brief Initializes an already allocated color with the specified red, green,
 *	  blue and alpha value.
 *
 * @param red The red value of the color, between 0.0 and 1.0
 * @param green The green value of the color, between 0.0 and 1.0
 * @param blue The blue value of the color, between 0.0 and 1.0
 * @param alpha The alpha value of the color, between 0.0 and 1.0
 * @return A color initialized with the specified red, green, blue and alpha
 *	   value
 */
- (instancetype)initWithRed: (float)red
		      green: (float)green
		       blue: (float)blue
		      alpha: (float)alpha;

/*!
 * @brief Returns the red, green, blue and alpha value of the color.
 *
 * @param red A pointer to store the red value of the color
 * @param green A pointer to store the green value of the color
 * @param blue A pointer to store the blue value of the color
 * @param alpha An optional pointer to store the alpha of the color
 */
- (void)getRed: (float *)red
	 green: (float *)green
	  blue: (float *)blue
	 alpha: (nullable float *)alpha;
@end

OF_ASSUME_NONNULL_END
