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
static OFMatrix4x4 *sRGBToXYZMatrix, *XYZToSRGBMatrix;
static OFOnceControl sRGBMatricesOnceControl = OFOnceControlInitValue;

static OFColorSpace *displayP3ColorSpace, *linearDisplayP3ColorSpace;
static OFMatrix4x4 *displayP3ToXYZMatrix, *XYZToDisplayP3Matrix;
static OFOnceControl displayP3MatricesOnceControl = OFOnceControlInitValue;

static OFColorSpace *adobeRGBColorSpace, *linearAdobeRGBColorSpace;
static OFMatrix4x4 *adobeRGBToXYZMatrix, *XYZToAdobeRGBMatrix;
static OFOnceControl adobeRGBMatricesOnceControl = OFOnceControlInitValue;

static void
identityTF(OFColorSpace *colorSpace, OFVector4D *vector)
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
sRGBEOTF(OFColorSpace *colorSpace, OFVector4D *vector)
{
	vector->x = sRGBEOTFPrimitive(vector->x);
	vector->y = sRGBEOTFPrimitive(vector->y);
	vector->z = sRGBEOTFPrimitive(vector->z);
}

static void
sRGBOETF(OFColorSpace *colorSpace, OFVector4D *vector)
{
	vector->x = sRGBOETFPrimitive(vector->x);
	vector->y = sRGBOETFPrimitive(vector->y);
	vector->z = sRGBOETFPrimitive(vector->z);
}

static void
initSRGBMatrices(void)
{
	sRGBToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float[4][4]) {
		{ 0.4123908f, 0.3575843f, 0.1804808f, 0.0f },
		{ 0.2126390f, 0.7151687f, 0.0721923f, 0.0f },
		{ 0.0193308f, 0.1191948f, 0.9505322f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToSRGBMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float[4][4]) {
		{ 3.2409699f, -1.5373832f, -0.4986108f, 0.0f },
		{ -0.9692436f, 1.8759675f, 0.0415551f, 0.0f },
		{ 0.0556301f, -0.2039770f, 1.0569715f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
}

static void
initSRGBColorSpace(void)
{
	OFOnce(&sRGBMatricesOnceControl, initSRGBMatrices);

	sRGBColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: sRGBEOTF
		      OETF: sRGBOETF
	    RGBToXYZMatrix: sRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToSRGBMatrix];
}

static void
initLinearSRGBColorSpace(void)
{
	OFOnce(&sRGBMatricesOnceControl, initSRGBMatrices);

	linearSRGBColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: sRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToSRGBMatrix];
}

static void
initDisplayP3Matrices(void)
{
	displayP3ToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float[4][4]) {
		{ 0.4865709f, 0.2656677f, 0.1982173f, 0.0f },
		{ 0.2289746f, 0.6917385f, 0.0792869f, 0.0f },
		{ 0.0f, 0.0451134f, 1.0439444f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToDisplayP3Matrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float[4][4]) {
		{ 2.4934969f, -0.9313836f, -0.4027108f, 0.0f },
		{ -0.8294890f, 1.7626641f, 0.0236247f, 0.0f },
		{ 0.0358458f, -0.0761724f, 0.9568845f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
}

static void
initDisplayP3ColorSpace(void)
{
	OFOnce(&displayP3MatricesOnceControl, initDisplayP3Matrices);

	displayP3ColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: sRGBEOTF
		      OETF: sRGBOETF
	    RGBToXYZMatrix: displayP3ToXYZMatrix
	    XYZToRGBMatrix: XYZToDisplayP3Matrix];
}

static void
initLinearDisplayP3ColorSpace(void)
{
	OFOnce(&displayP3MatricesOnceControl, initDisplayP3Matrices);

	linearDisplayP3ColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: displayP3ToXYZMatrix
	    XYZToRGBMatrix: XYZToDisplayP3Matrix];
}

static OF_INLINE float
adobeRGBEOTFPrimitive(float value)
{
	return powf(value, 563.0f / 256.0f);
}

static OF_INLINE float
adobeRGBOETFPrimitive(float value)
{
	return powf(value, 256.0f / 563.0f);
}

static void
adobeRGBEOTF(OFColorSpace *colorSpace, OFVector4D *vector)
{
	vector->x = adobeRGBEOTFPrimitive(vector->x);
	vector->y = adobeRGBEOTFPrimitive(vector->y);
	vector->z = adobeRGBEOTFPrimitive(vector->z);
}

static void
adobeRGBOETF(OFColorSpace *colorSpace, OFVector4D *vector)
{
	vector->x = adobeRGBOETFPrimitive(vector->x);
	vector->y = adobeRGBOETFPrimitive(vector->y);
	vector->z = adobeRGBOETFPrimitive(vector->z);
}

static void
initAdobeRGBMatrices(void)
{
	adobeRGBToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float[4][4]) {
		{ 0.5766690f, 0.1855582f, 0.1882286f, 0.0f },
		{ 0.2973450f, 0.6273636f, 0.0752915f, 0.0f },
		{ 0.0270314f, 0.0706889f, 0.9913375f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToAdobeRGBMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float[4][4]) {
		{ 2.0415879f, -0.5650070f, -0.3447314f, 0.0f },
		{ -0.9692436f, 1.8759675f, 0.0415551f, 0.0f },
		{ 0.0134443f, -0.1183624f, 1.0151750f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
}

static void
initAdobeRGBColorSpace(void)
{
	OFOnce(&adobeRGBMatricesOnceControl, initAdobeRGBMatrices);

	adobeRGBColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: adobeRGBEOTF
		      OETF: adobeRGBOETF
	    RGBToXYZMatrix: adobeRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToAdobeRGBMatrix];
}

static void
initLinearAdobeRGBColorSpace(void)
{
	OFOnce(&displayP3MatricesOnceControl, initDisplayP3Matrices);

	linearAdobeRGBColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: adobeRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToAdobeRGBMatrix];
}

@implementation OFColorSpaceSingleton
OF_SINGLETON_METHODS
@end

@implementation OFColorSpace
@synthesize EOTF = _EOTF, OETF = _OETF, RGBToXYZMatrix = _RGBToXYZMatrix;
@synthesize XYZToRGBMatrix = _XYZToRGBMatrix;

+ (instancetype)colorSpaceWithEOTF: (OFColorSpaceTransferFunction)EOTF
			      OETF: (OFColorSpaceTransferFunction)OETF
		    RGBToXYZMatrix: (OFMatrix4x4 *)RGBToXYZMatrix
		    XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithEOTF: EOTF
				  OETF: OETF
			RGBToXYZMatrix: RGBToXYZMatrix
			XYZToRGBMatrix: XYZToRGBMatrix]);
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

+ (OFColorSpace *)displayP3ColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initDisplayP3ColorSpace);

	return displayP3ColorSpace;
}

+ (OFColorSpace *)linearDisplayP3ColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initLinearDisplayP3ColorSpace);

	return linearDisplayP3ColorSpace;
}

+ (OFColorSpace *)adobeRGBColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initAdobeRGBColorSpace);

	return adobeRGBColorSpace;
}

+ (OFColorSpace *)linearAdobeRGBColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initLinearAdobeRGBColorSpace);

	return linearAdobeRGBColorSpace;
}

- (instancetype)initWithEOTF: (OFColorSpaceTransferFunction)EOTF
			OETF: (OFColorSpaceTransferFunction)OETF
	      RGBToXYZMatrix: (OFMatrix4x4 *)RGBToXYZMatrix
	      XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix
{
	self = [super init];

	_EOTF = EOTF;
	_OETF = OETF;
	_RGBToXYZMatrix = objc_retain(RGBToXYZMatrix);
	_XYZToRGBMatrix = objc_retain(XYZToRGBMatrix);

	return self;
}

- (void)dealloc
{
	objc_release(_RGBToXYZMatrix);
	objc_release(_XYZToRGBMatrix);

	[super dealloc];
}
@end
