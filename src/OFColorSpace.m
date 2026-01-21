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

static OFColorSpace *sRGBColorSpace, *linearSRGBColorSpace, *BT709ColorSpace;
static OFMatrix4x4 *sRGBToXYZMatrix, *XYZToSRGBMatrix;
static OFOnceControl sRGBMatricesOnceControl = OFOnceControlInitValue;

static OFColorSpace *displayP3ColorSpace, *linearDisplayP3ColorSpace;
static OFMatrix4x4 *displayP3ToXYZMatrix, *XYZToDisplayP3Matrix;
static OFOnceControl displayP3MatricesOnceControl = OFOnceControlInitValue;

static OFColorSpace *BT2020ColorSpace, *linearBT2020ColorSpace;
static OFMatrix4x4 *BT2020ToXYZMatrix, *XYZToBT2020Matrix;
static OFOnceControl BT2020MatricesOnceControl = OFOnceControlInitValue;

static OFColorSpace *adobeRGBColorSpace, *linearAdobeRGBColorSpace;
static OFMatrix4x4 *adobeRGBToXYZMatrix, *XYZToAdobeRGBMatrix;
static OFOnceControl adobeRGBMatricesOnceControl = OFOnceControlInitValue;

static void
identityTF(OFVector4D *vectors, size_t count)
{
}

static OF_INLINE float
sRGBEOTFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	if (absValue <= 0.04045f)
		return value / 12.92f;
	else
		return sign * powf((absValue + 0.055f) / 1.055f, 2.4f);
}

static OF_INLINE float
sRGBOETFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	if (absValue <= 0.0031308f)
		return value * 12.92f;
	else
		return sign * (1.055f * powf(absValue, 1.0f / 2.4f) - 0.055f);
}

static void
sRGBEOTF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = sRGBEOTFPrimitive(vectors[i].x);
		vectors[i].y = sRGBEOTFPrimitive(vectors[i].y);
		vectors[i].z = sRGBEOTFPrimitive(vectors[i].z);
	}
}

static void
sRGBOETF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = sRGBOETFPrimitive(vectors[i].x);
		vectors[i].y = sRGBOETFPrimitive(vectors[i].y);
		vectors[i].z = sRGBOETFPrimitive(vectors[i].z);
	}
}

static void
initSRGBMatrices(void)
{
	sRGBToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
		{ 0.4123908f, 0.3575843f, 0.1804808f, 0.0f },
		{ 0.2126390f, 0.7151687f, 0.0721923f, 0.0f },
		{ 0.0193308f, 0.1191948f, 0.9505322f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToSRGBMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
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
	    XYZToRGBMatrix: XYZToSRGBMatrix
		    linear: false];
}

static void
initLinearSRGBColorSpace(void)
{
	OFOnce(&sRGBMatricesOnceControl, initSRGBMatrices);

	linearSRGBColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: sRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToSRGBMatrix
		    linear: true];
}

static OF_INLINE float
BT709EOTFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	if (absValue < 0.081f)
		return value / 4.5f;
	else
		return sign * powf((absValue + 0.099f) / 1.099f, 1.0f / 0.45f);
}

static OF_INLINE float
BT709OETFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	if (absValue < 0.018f)
		return 4.5f * value;
	else
		return sign * (1.099f * powf(absValue, 0.45f) - 0.099f);
}

static void
BT709EOTF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = BT709EOTFPrimitive(vectors[i].x);
		vectors[i].y = BT709EOTFPrimitive(vectors[i].y);
		vectors[i].z = BT709EOTFPrimitive(vectors[i].z);
	}
}

static void
BT709OETF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = BT709OETFPrimitive(vectors[i].x);
		vectors[i].y = BT709OETFPrimitive(vectors[i].y);
		vectors[i].z = BT709OETFPrimitive(vectors[i].z);
	}
}

static void
initBT709ColorSpace(void)
{
	OFOnce(&sRGBMatricesOnceControl, initSRGBMatrices);

	BT709ColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: BT709EOTF
		      OETF: BT709OETF
	    RGBToXYZMatrix: sRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToSRGBMatrix
		    linear: false];
}

static void
initDisplayP3Matrices(void)
{
	displayP3ToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
		{ 0.4865709f, 0.2656677f, 0.1982173f, 0.0f },
		{ 0.2289746f, 0.6917385f, 0.0792869f, 0.0f },
		{ 0.0f, 0.0451134f, 1.0439444f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToDisplayP3Matrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
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
	    XYZToRGBMatrix: XYZToDisplayP3Matrix
		    linear: false];
}

static void
initLinearDisplayP3ColorSpace(void)
{
	OFOnce(&displayP3MatricesOnceControl, initDisplayP3Matrices);

	linearDisplayP3ColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: displayP3ToXYZMatrix
	    XYZToRGBMatrix: XYZToDisplayP3Matrix
		    linear: true];
}

static OF_INLINE float
BT2020OETFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	if (absValue < 0.0181f)
		return 4.5f * value;
	else
		return sign * (1.0993f * powf(absValue, 0.45f) - 0.0993f);
}

static OF_INLINE float
BT2020EOTFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	if (absValue < BT2020OETFPrimitive(0.0181f))
		return value / 4.5f;
	else
		return sign *
		    powf((absValue + 0.0993f) / 1.0993f, 1.0f / 0.45f);
}

static void
BT2020EOTF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = BT2020EOTFPrimitive(vectors[i].x);
		vectors[i].y = BT2020EOTFPrimitive(vectors[i].y);
		vectors[i].z = BT2020EOTFPrimitive(vectors[i].z);
	}
}

static void
BT2020OETF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = BT2020OETFPrimitive(vectors[i].x);
		vectors[i].y = BT2020OETFPrimitive(vectors[i].y);
		vectors[i].z = BT2020OETFPrimitive(vectors[i].z);
	}
}

static void
initBT2020Matrices(void)
{
	BT2020ToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
		{ 0.6369580f, 0.1446169f, 0.1688810, 0.0f },
		{ 0.2627002f, 0.6779981f, 0.0593017, 0.0f },
		{ 0.0f, 0.0280727f, 1.0609851, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToBT2020Matrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
		{ 1.7166512f, -0.3556708f, -0.2533663f, 0.0f },
		{ -0.6666844f, 1.6164812f, 0.0157685f, 0.0f },
		{ 0.0176399f, -0.0427706f, 0.9421031f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
}

static void
initBT2020ColorSpace(void)
{
	OFOnce(&BT2020MatricesOnceControl, initBT2020Matrices);

	BT2020ColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: BT2020EOTF
		      OETF: BT2020OETF
	    RGBToXYZMatrix: BT2020ToXYZMatrix
	    XYZToRGBMatrix: XYZToBT2020Matrix
		    linear: false];
}

static void
initLinearBT2020ColorSpace(void)
{
	OFOnce(&BT2020MatricesOnceControl, initBT2020Matrices);

	linearBT2020ColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: BT2020ToXYZMatrix
	    XYZToRGBMatrix: XYZToBT2020Matrix
		    linear: true];
}

static OF_INLINE float
adobeRGBEOTFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	return sign * powf(absValue, 563.0f / 256.0f);
}

static OF_INLINE float
adobeRGBOETFPrimitive(float value)
{
	float sign = (value < 0.0f ? -1.0f : 1.0f);
	float absValue = fabs(value);

	return sign * powf(absValue, 256.0f / 563.0f);
}

static void
adobeRGBEOTF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = adobeRGBEOTFPrimitive(vectors[i].x);
		vectors[i].y = adobeRGBEOTFPrimitive(vectors[i].y);
		vectors[i].z = adobeRGBEOTFPrimitive(vectors[i].z);
	}
}

static void
adobeRGBOETF(OFVector4D *vectors, size_t count)
{
	for (size_t i = 0; i < count; i++) {
		vectors[i].x = adobeRGBOETFPrimitive(vectors[i].x);
		vectors[i].y = adobeRGBOETFPrimitive(vectors[i].y);
		vectors[i].z = adobeRGBOETFPrimitive(vectors[i].z);
	}
}

static void
initAdobeRGBMatrices(void)
{
	adobeRGBToXYZMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
		{ 0.5766690f, 0.1855582f, 0.1882286f, 0.0f },
		{ 0.2973450f, 0.6273636f, 0.0752915f, 0.0f },
		{ 0.0270314f, 0.0706889f, 0.9913375f, 0.0f },
		{ 0.0f, 0.0f, 0.0f, 1.0f }
	}];
	XYZToAdobeRGBMatrix = [[OFMatrix4x4 alloc]
	    initWithValues: (const float [4][4]) {
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
	    XYZToRGBMatrix: XYZToAdobeRGBMatrix
		    linear: false];
}

static void
initLinearAdobeRGBColorSpace(void)
{
	OFOnce(&displayP3MatricesOnceControl, initDisplayP3Matrices);

	linearAdobeRGBColorSpace = [[OFColorSpaceSingleton alloc]
	      initWithEOTF: identityTF
		      OETF: identityTF
	    RGBToXYZMatrix: adobeRGBToXYZMatrix
	    XYZToRGBMatrix: XYZToAdobeRGBMatrix
		    linear: true];
}

@implementation OFColorSpaceSingleton
OF_SINGLETON_METHODS
@end

@implementation OFColorSpace
@synthesize EOTF = _EOTF, OETF = _OETF, RGBToXYZMatrix = _RGBToXYZMatrix;
@synthesize XYZToRGBMatrix = _XYZToRGBMatrix, linear = _linear;

+ (instancetype)colorSpaceWithEOTF: (OFColorSpaceTransferFunction)EOTF
			      OETF: (OFColorSpaceTransferFunction)OETF
		    RGBToXYZMatrix: (OFMatrix4x4 *)RGBToXYZMatrix
		    XYZToRGBMatrix: (OFMatrix4x4 *)XYZToRGBMatrix
			    linear: (bool)linear
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithEOTF: EOTF
				  OETF: OETF
			RGBToXYZMatrix: RGBToXYZMatrix
			XYZToRGBMatrix: XYZToRGBMatrix
				linear: linear]);
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

+ (OFColorSpace *)BT709ColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initBT709ColorSpace);

	return BT709ColorSpace;
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

+ (OFColorSpace *)BT2020ColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initBT2020ColorSpace);

	return BT2020ColorSpace;
}

+ (OFColorSpace *)linearBT2020ColorSpace
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initLinearBT2020ColorSpace);

	return linearBT2020ColorSpace;
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
		      linear: (bool)linear
{
	self = [super init];

	_EOTF = EOTF;
	_OETF = OETF;
	_RGBToXYZMatrix = objc_retain(RGBToXYZMatrix);
	_XYZToRGBMatrix = objc_retain(XYZToRGBMatrix);
	_linear = linear;

	return self;
}

- (void)dealloc
{
	objc_release(_RGBToXYZMatrix);
	objc_release(_XYZToRGBMatrix);

	[super dealloc];
}
@end
