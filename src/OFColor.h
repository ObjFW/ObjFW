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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFColor OFColor.h ObjFW/ObjFW.h
 *
 * @brief A class for storing a color.
 */
@interface OFColor: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFColor *black;
@property (class, readonly, nonatomic) OFColor *silver;
@property (class, readonly, nonatomic) OFColor *gray;
@property (class, readonly, nonatomic) OFColor *grey
    OF_DEPRECATED(ObjFW, 1, 1, "Use +[gray] instead");
@property (class, readonly, nonatomic) OFColor *white;
@property (class, readonly, nonatomic) OFColor *maroon;
@property (class, readonly, nonatomic) OFColor *red;
@property (class, readonly, nonatomic) OFColor *purple;
@property (class, readonly, nonatomic) OFColor *fuchsia;
@property (class, readonly, nonatomic) OFColor *green;
@property (class, readonly, nonatomic) OFColor *lime;
@property (class, readonly, nonatomic) OFColor *olive;
@property (class, readonly, nonatomic) OFColor *yellow;
@property (class, readonly, nonatomic) OFColor *navy;
@property (class, readonly, nonatomic) OFColor *blue;
@property (class, readonly, nonatomic) OFColor *teal;
@property (class, readonly, nonatomic) OFColor *aqua;
#endif

/**
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

/**
 * @brief Returns the HTML color `black`.
 *
 * The RGBA value is (0, 0, 0, 1).
 *
 * @return The HTML color `black`
 */
+ (OFColor *)black;

/**
 * @brief Returns the HTML color `silver`.
 *
 * The RGBA value is (0.75, 0.75, 0.75, 1).
 *
 * @return The HTML color `silver`
 */
+ (OFColor *)silver;

/**
 * @brief Returns the HTML color `gray`.
 *
 * The RGBA value is (0.5, 0.5, 0.5, 1).
 *
 * @return The HTML color `gray`
 */
+ (OFColor *)gray;

/**
 * @brief Returns the HTML color `gray`.
 *
 * @deprecated Use @ref gray instead.
 *
 * The RGBA value is (0.5, 0.5, 0.5, 1).
 *
 * @return The HTML color `gray`
 */
+ (OFColor *)grey OF_DEPRECATED(ObjFW, 1, 1, "Use +[gray] instead");

/**
 * @brief Returns the HTML color `white`.
 *
 * The RGBA value is (1, 1, 1, 1).
 *
 * @return The HTML color `white`
 */
+ (OFColor *)white;

/**
 * @brief Returns the HTML color `maroon`.
 *
 * The RGBA value is (0.5, 0, 0, 1).
 *
 * @return The HTML color `maroon`
 */
+ (OFColor *)maroon;

/**
 * @brief Returns the HTML color `red`.
 *
 * The RGBA value is (1, 0, 0, 1).
 *
 * @return The HTML color `red`
 */
+ (OFColor *)red;

/**
 * @brief Returns the HTML color `purple`.
 *
 * The RGBA value is (0.5, 0, 0.5, 1).
 *
 * @return The HTML color `purple`
 */
+ (OFColor *)purple;

/**
 * @brief Returns the HTML color `fuchsia`.
 *
 * The RGBA value is (1, 0, 1, 1).
 *
 * @return The HTML color `fuchsia`
 */
+ (OFColor *)fuchsia;

/**
 * @brief Returns the HTML color `green`.
 *
 * The RGBA value is (0, 0.5, 0, 1).
 *
 * @return The HTML color `green`
 */
+ (OFColor *)green;

/**
 * @brief Returns the HTML color `lime`.
 *
 * The RGBA value is (0, 1, 0, 1).
 *
 * @return The HTML color `lime`
 */
+ (OFColor *)lime;

/**
 * @brief Returns the HTML color `olive`.
 *
 * The RGBA value is (0.5, 0.5, 0, 1).
 *
 * @return The HTML color `olive`
 */
+ (OFColor *)olive;

/**
 * @brief Returns the HTML color `yellow`.
 *
 * The RGBA value is (1, 1, 0, 1).
 *
 * @return The HTML color `yellow`
 */
+ (OFColor *)yellow;

/**
 * @brief Returns the HTML color `navy`.
 *
 * The RGBA value is (0, 0, 0.5, 1).
 *
 * @return The HTML color `navy`
 */
+ (OFColor *)navy;

/**
 * @brief Returns the HTML color `blue`.
 *
 * The RGBA value is (0, 0, 1, 1).
 *
 * @return The HTML color `blue`
 */
+ (OFColor *)blue;

/**
 * @brief Returns the HTML color `teal`.
 *
 * The RGBA value is (0, 0.5, 0.5, 1).
 *
 * @return The HTML color `teal`
 */
+ (OFColor *)teal;

/**
 * @brief Returns the HTML color `aqua`.
 *
 * The RGBA value is (0, 1, 1, 1).
 *
 * @return The HTML color `aqua`
 */
+ (OFColor *)aqua;

/**
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

/**
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
