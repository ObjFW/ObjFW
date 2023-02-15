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
	OFVector3D vec3;

	TEST(@"+[identityMatrix]",
	    memcmp([[OFMatrix4x4 identityMatrix] values], (float [16]){
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	    }, 16 * sizeof(float)) == 0)

	TEST(@"+[matrixWithValues:]",
	    (matrix = [OFMatrix4x4 matrixWithValues: (float [16]){
		 1,  2,  3,  4,
		 5,  6,  7,  8,
		 9, 10, 11, 12,
		13, 14, 15, 16
	    }]))

	TEST(@"-[description]",
	    [matrix.description isEqual: @"<OFMatrix4x4: {\n"
					 @"\t1 5 9 13\n"
					 @"\t2 6 10 14\n"
					 @"\t3 7 11 15\n"
					 @"\t4 8 12 16\n"
					 @"}>"])

	TEST(@"-[transpose]",
	    R([matrix transpose]) && memcmp(matrix.values, (float [16]){
		1, 5,  9, 13,
		2, 6, 10, 14,
		3, 7, 11, 15,
		4, 8, 12, 16
	    }, 16 * sizeof(float)) == 0)

	TEST(@"-[isEqual:]", [[OFMatrix4x4 identityMatrix] isEqual:
	    [OFMatrix4x4 matrixWithValues: (float [16]){
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	    }]])

	TEST(@"-[copy]", (matrix2 = [matrix copy]) && [matrix2 isEqual: matrix])

	TEST(@"-[multiplyWithMatrix:] #1",
	    R([matrix2 multiplyWithMatrix: [OFMatrix4x4 identityMatrix]]) &&
	    [matrix2 isEqual: matrix])

	matrix2 = [OFMatrix4x4 matrixWithValues: (float [16]){
		100, 500,  900, 1300,
		200, 600, 1000, 1400,
		300, 700, 1100, 1500,
		400, 800, 1200, 1600
	}];
	TEST(@"-[multiplyWithMatrix:] #2",
	    R([matrix2 multiplyWithMatrix: matrix]) &&
	    [matrix2 isEqual: [OFMatrix4x4 matrixWithValues: (float [16]){
		 9000, 20200, 31400, 42600,
		10000, 22800, 35600, 48400,
		11000, 25400, 39800, 54200,
		12000, 28000, 44000, 60000
	    }]])

	TEST(@"-[transformedVector3D:]",
	    R((vec3 = [matrix transformedVector3D: OFMakeVector3D(1, 2, 3)])) &&
	    vec3.x == 14 && vec3.y == 38 && vec3.z == 62)

	objc_autoreleasePoolPop(pool);
}
@end
