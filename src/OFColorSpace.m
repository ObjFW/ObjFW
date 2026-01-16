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

#import "OFColorSpace.h"
#import "OFMatrix4x4.h"

@interface OFColorSpaceSingleton: OFColorSpace
@end

static OFColorSpace *sRGBColorSpace, *linearSRGBColorSpace;

static void
identityTF(OFColorSpace *colorSpace, float *red, float *green, float *blue)
{
}

static OF_INLINE float
sRGBEOTFPrimitive(float value)
{
	if (value <= 0.04045f)
		return value / 12.92f;
	else
		return powf((value + 0.055f) / 1.055f, 2.4f);
}

static OF_INLINE float
sRGBOETFPrimitive(float value)
{
	if (value <= 0.0031308f)
		return value * 12.92f;
	else
		return 1.055f * powf(value, 1.0f / 2.4f) - 0.055f;
}

static void
sRGBEOTF(OFColorSpace *colorSpace, float *red, float *green, float *blue)
{
	*red = sRGBEOTFPrimitive(*red);
	*green = sRGBEOTFPrimitive(*green);
	*blue = sRGBEOTFPrimitive(*blue);
}

static void
sRGBOETF(OFColorSpace *colorSpace, float *red, float *green, float *blue)
{
	*red = sRGBOETFPrimitive(*red);
	*green = sRGBOETFPrimitive(*green);
	*blue = sRGBOETFPrimitive(*blue);
}

static void
initSRGBColorSpace(void)
{
	void *pool = objc_autoreleasePoolPush();
	OFMatrix4x4 *RGBToCIEXYZMatrix, *CIEXYZToRGBMatrix;

	RGBToCIEXYZMatrix = [OFMatrix4x4 matrixWithValues: (const float[4][4]) {
		{ 0.4124f, 0.3576f, 0.1805f, 0.0f },
		{ 0.2126f, 0.7152f, 0.0722f, 0.0f },
		{ 0.0193f, 0.1192f, 0.9505f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	CIEXYZToRGBMatrix = [OFMatrix4x4 matrixWithValues: (const float[4][4]) {
		{ 3.2406255f, -1.5372080f, -0.4986286f, 0.0f },
		{ -0.9689307f, 1.8757561f, 0.0415175f, 0.0f },
		{ 0.0557101f, -0.2040211f, 1.0569959f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];

	sRGBColorSpace = [[OFColorSpaceSingleton alloc]
		 initWithEOTF: sRGBEOTF
			 OETF: sRGBOETF
	    RGBToCIEXYZMatrix: RGBToCIEXYZMatrix
	    CIEXYZToRGBMatrix: CIEXYZToRGBMatrix];

	objc_autoreleasePoolPop(pool);
}

static void
initLinearSRGBColorSpace(void)
{
	void *pool = objc_autoreleasePoolPush();
	OFMatrix4x4 *RGBToCIEXYZMatrix, *CIEXYZToRGBMatrix;

	RGBToCIEXYZMatrix = [OFMatrix4x4 matrixWithValues: (const float[4][4]) {
		{ 0.4124f, 0.3576f, 0.1805f, 0.0f },
		{ 0.2126f, 0.7152f, 0.0722f, 0.0f },
		{ 0.0193f, 0.1192f, 0.9505f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	CIEXYZToRGBMatrix = [OFMatrix4x4 matrixWithValues: (const float[4][4]) {
		{ 3.2406255f, -1.5372080f, -0.4986286f, 0.0f },
		{ -0.9689307f, 1.8757561f, 0.0415175f, 0.0f },
		{ 0.0557101f, -0.2040211f, 1.0569959f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];

	linearSRGBColorSpace = [[OFColorSpaceSingleton alloc]
		 initWithEOTF: identityTF
			 OETF: identityTF
	    RGBToCIEXYZMatrix: RGBToCIEXYZMatrix
	    CIEXYZToRGBMatrix: CIEXYZToRGBMatrix];

	objc_autoreleasePoolPop(pool);
}

@implementation OFColorSpaceSingleton
OF_SINGLETON_METHODS
@end

@implementation OFColorSpace
@synthesize EOTF = _EOTF, OETF = _OETF, RGBToCIEXYZMatrix = _RGBToCIEXYZMatrix;
@synthesize CIEXYZToRGBMatrix = _CIEXYZToRGBMatrix;

+ (instancetype)colorSpaceWithEOTF: (OFColorSpaceTransferFunction)EOTF
			      OETF: (OFColorSpaceTransferFunction)OETF
		 RGBToCIEXYZMatrix: (OFMatrix4x4 *)RGBToCIEXYZMatrix
		 CIEXYZToRGBMatrix: (OFMatrix4x4 *)CIEXYZToRGBMatrix
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithEOTF: EOTF
				  OETF: OETF
		     RGBToCIEXYZMatrix: RGBToCIEXYZMatrix
		     CIEXYZToRGBMatrix: CIEXYZToRGBMatrix]);
}

+ (OFColorSpace *)sRGBColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initSRGBColorSpace);

	return sRGBColorSpace;
}

+ (OFColorSpace *)linearSRGBColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initLinearSRGBColorSpace);

	return linearSRGBColorSpace;
}

- (instancetype)initWithEOTF: (OFColorSpaceTransferFunction)EOTF
			OETF: (OFColorSpaceTransferFunction)OETF
	   RGBToCIEXYZMatrix: (OFMatrix4x4 *)RGBToCIEXYZMatrix
	   CIEXYZToRGBMatrix: (OFMatrix4x4 *)CIEXYZToRGBMatrix
{
	self = [super init];

	_EOTF = EOTF;
	_OETF = OETF;
	_RGBToCIEXYZMatrix = objc_retain(RGBToCIEXYZMatrix);
	_CIEXYZToRGBMatrix = objc_retain(CIEXYZToRGBMatrix);

	return self;
}

- (void)dealloc
{
	objc_release(_RGBToCIEXYZMatrix);
	objc_release(_CIEXYZToRGBMatrix);

	[super dealloc];
}
@end
