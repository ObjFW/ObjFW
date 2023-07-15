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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFMatrix4x4Tests";

@implementation TestsAppDelegate (OFMatrix4x4Tests)
- (void)matrix4x4Tests
{
	void *pool = objc_autoreleasePoolPush();
	OFMatrix4x4 *matrix, *matrix2;
	OFVector4D point;

	TEST(@"+[identityMatrix]",
	    memcmp([[OFMatrix4x4 identityMatrix] values], (const float [4][4]){
		{ 1, 0, 0, 0 },
		{ 0, 1, 0, 0 },
		{ 0, 0, 1, 0 },
		{ 0, 0, 0, 1 }
	    }, 16 * sizeof(float)) == 0)

	TEST(@"+[matrixWithValues:]",
	    (matrix = [OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{  1,  2,  3,  4 },
		{  5,  6,  7,  8 },
		{  9, 10, 11, 12 },
		{ 13, 14, 15, 16 }
	    }]))

	TEST(@"-[description]",
	    [matrix.description isEqual: @"<OFMatrix4x4: {\n"
					 @"\t1 2 3 4\n"
					 @"\t5 6 7 8\n"
					 @"\t9 10 11 12\n"
					 @"\t13 14 15 16\n"
					 @"}>"])

	TEST(@"-[isEqual:]", [[OFMatrix4x4 identityMatrix] isEqual:
	    [OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{ 1, 0, 0, 0 },
		{ 0, 1, 0, 0 },
		{ 0, 0, 1, 0 },
		{ 0, 0, 0, 1 }
	    }]])

	TEST(@"-[copy]", (matrix2 = [matrix copy]) && [matrix2 isEqual: matrix])

	TEST(@"-[multiplyWithMatrix:] #1",
	    R([matrix2 multiplyWithMatrix: [OFMatrix4x4 identityMatrix]]) &&
	    [matrix2 isEqual: matrix])

	matrix2 = [OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{  100,  200,  300,  400 },
		{  500,  600,  700,  800 },
		{  900, 1000, 1100, 1200 },
		{ 1300, 1400, 1500, 1600 }
	}];
	TEST(@"-[multiplyWithMatrix:] #2",
	    R([matrix2 multiplyWithMatrix: matrix]) &&
	    [matrix2 isEqual:
	    [OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{  9000, 10000, 11000, 12000 },
		{ 20200, 22800, 25400, 28000 },
		{ 31400, 35600, 39800, 44000 },
		{ 42600, 48400, 54200, 60000 }
	    }]])

	TEST(@"[-translateWithVector:]",
	    (matrix2 = [OFMatrix4x4 identityMatrix]) &&
	    R([matrix2 translateWithVector: OFMakeVector3D(1, 2, 3)]) &&
	    R(point =
	    [matrix2 transformedVector: OFMakeVector4D(2, 3, 4, 1)]) &&
	    point.x == 3 && point.y == 5 && point.z == 7 && point.w == 1)

	TEST(@"-[scaleWithVector:]",
	    R([matrix2 scaleWithVector: OFMakeVector3D(-1, 0.5f, 2)]) &&
	    R(point =
	    [matrix2 transformedVector: OFMakeVector4D(2, 3, 4, 1)]) &&
	    point.x == -3 && point.y == 2.5 && point.z == 14 && point.w == 1)

	TEST(@"-[transformedVector:]",
	    R((point =
	    [matrix transformedVector: OFMakeVector4D(1, 2, 3, 1)])) &&
	    point.x == 18 && point.y == 46 && point.z == 74 && point.w == 102)

	objc_autoreleasePoolPop(pool);
}
@end
