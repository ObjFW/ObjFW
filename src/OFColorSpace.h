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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFColorSpace;
@class OFMatrix4x4;

/**
 * @brief A transfer function for a color space.
 *
 * The function transforms an array of vectors in-place. The `w` component of
 * the vectors should not be touched.
 *
 * The same type is used for both the EOTF and the OETF.
 *
 * @note The vectors needs to be 16 byte aligned.
 *
 * @param vectors The vectors to transform in-place
 * @param count The number of vectors to transform
 */
typedef void (*OFColorSpaceTransferFunction)(OFVector4D *vectors,
    size_t count);

/**
 * @class OFColorSpace OFColorSpace.h ObjFW/ObjFW.h
 *
 * @brief A class representing a color space.
 */
@interface OFColorSpace: OFObject
{
	OFColorSpaceTransferFunction _EOTF, _OETF;
	OFMatrix4x4 *_RGBToXYZMatrix, *_XYZToRGBMatrix;
	bool _linear;
	OF_RESERVE_IVARS(OFColorSpace, 4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, retain, nonatomic) OFColorSpace *sRGBColorSpace;
@property (class, readonly, retain, nonatomic)
    OFColorSpace *linearSRGBColorSpace;
@property (class, readonly, retain, nonatomic)
    OFColorSpace *displayP3ColorSpace;
@property (class, readonly, retain, nonatomic)
    OFColorSpace *linearDisplayP3ColorSpace;
@property (class, readonly, retain, nonatomic) OFColorSpace *BT2020ColorSpace;
@property (class, readonly, retain, nonatomic)
    OFColorSpace *linearBT2020ColorSpace;
@property (class, readonly, retain, nonatomic) OFColorSpace *adobeRGBColorSpace;
@property (class, readonly, retain, nonatomic)
    OFColorSpace *linearAdobeRGBColorSpace;
#endif

/**
 * @brief The Electro-Optical Transfer Function of the color space.
 *
 * This maps a non-linear RGB value to a linear RGB value.
 */
@property (readonly, nonatomic) OFColorSpaceTransferFunction EOTF;

/**
 * @brief The Opto-Electronic Transfer Function of the color space.
 *
 * This maps a linear RGB value to a non-linear RGB value.
 */
@property (readonly, nonatomic) OFColorSpaceTransferFunction OETF;

/**
 * @brief A matrix to map a linear RGB value to a CIE XYZ value.
 */
@property (readonly, retain, nonatomic) OFMatrix4x4 *RGBToXYZMatrix;

/**
 * @brief A matrix to map a CIE XYZ value to a linear RGB value.
 */
@property (readonly, retain, nonatomic) OFMatrix4x4 *XYZToRGBMatrix;

/**
 * @brief Whether the color space is linear.
 */
@property (readonly, nonatomic, getter=isLinear) bool linear;

/**
 * @brief Creates a new color space with the specified parameters.
 *
 * @param EOTF The EOTF for the color space
 * @param OETF The OETF for the color space
 * @param RGBToXYZMatrix The RGB to CIE XYZ matrix for the color space
 * @param XYZToRGBMatrix The CIE XYZ to RGB matrix for the color space
 * @return An new, autoreleased color space
 */
+ (instancetype)colorSpaceWithEOTF: (OFColorSpaceTransferFunction)EOTF
			      OETF: (OFColorSpaceTransferFunction)OETF
		    RGBToXYZMatrix: (OFMatrix4x4 *)RGBToXYZMatrix
		    XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix
			    linear: (bool)linear;

/**
 * @brief The sRGB color space.
 */
+ (OFColorSpace *)sRGBColorSpace;

/**
 * @brief The sRGB color space with linear transfer function.
 */
+ (OFColorSpace *)linearSRGBColorSpace;

/**
 * @brief The Display P3 color space.
 */
+ (OFColorSpace *)displayP3ColorSpace;

/**
 * @brief The Display P3 color space with linear transfer function.
 */
+ (OFColorSpace *)linearDisplayP3ColorSpace;

/**
 * @brief The ITU-R Recommendation BT.2020 color space.
 */
+ (OFColorSpace *)BT2020ColorSpace;

/**
 * @brief The ITU-R Recommendation BT.2020 color space with linear transfer
 *	  function.
 */
+ (OFColorSpace *)linearBT2020ColorSpace;

/**
 * @brief The Adobe RGB (1998) color space.
 */
+ (OFColorSpace *)adobeRGBColorSpace;

/**
 * @brief The Adobe RGB (1998) color space with linear transfer function.
 */
+ (OFColorSpace *)linearAdobeRGBColorSpace;

/**
 * @brief Initializes the color space with the specified parameters.
 *
 * @param EOTF The EOTF for the color space
 * @param OETF The OETF for the color space
 * @param RGBToXYZMatrix The RGB to CIE XYZ matrix for the color space
 * @param XYZToRGBMatrix The CIE XYZ to RGB matrix for the color space
 * @return An initialized color space
 */
- (instancetype)initWithEOTF: (OFColorSpaceTransferFunction)EOTF
			OETF: (OFColorSpaceTransferFunction)OETF
	      RGBToXYZMatrix: (OFMatrix4x4 *)RGBToXYZMatrix
	      XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix
		      linear: (bool)linear;
@end

OF_ASSUME_NONNULL_END
