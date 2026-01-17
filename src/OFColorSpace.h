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
 * The same type is used for both the EOTF and the OETF.
 *
 * The vector needs to be 16 byte aligned.
 */
typedef void (*OFColorSpaceTransferFunction)(OFColorSpace *colorSpace,
    OFVector4D *vector);

/**
 * @class OFColorSpace OFColorSpace.h ObjFW/ObjFW.h
 *
 * @brief A class representing a color space.
 */
@interface OFColorSpace: OFObject
{
	OFColorSpaceTransferFunction _EOTF, _OETF;
	OFMatrix4x4 *_RGBToXYZMatrix, *_XYZToRGBMatrix;
	OF_RESERVE_IVARS(OFColorSpace, 4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, retain, nonatomic) OFColorSpace *sRGBColorSpace;
@property (class, readonly, retain, nonatomic)
    OFColorSpace *linearSRGBColorSpace;
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
		    XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix;

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
	      XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix;
@end

OF_ASSUME_NONNULL_END
