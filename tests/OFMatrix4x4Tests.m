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

#include "config.h"

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFMatrix4x4Tests: OTTestCase
{
	OFMatrix4x4 *_matrix;
}
@end

@implementation OFMatrix4x4Tests
- (void)setUp
{
	[super setUp];

	_matrix = [[OFMatrix4x4 alloc] initWithValues: (const float [4][4]){
		{  1,  2,  3,  4 },
		{  5,  6,  7,  8 },
		{  9, 10, 11, 12 },
		{ 13, 14, 15, 16 }
	}];
}

- (void)dealloc
{
	objc_release(_matrix);

	[super dealloc];
}

- (void)testIdentityMatrix
{
	OTAssertEqual(memcmp([[OFMatrix4x4 identityMatrix] values],
	    (const float [4][4]){
		{ 1, 0, 0, 0 },
		{ 0, 1, 0, 0 },
		{ 0, 0, 1, 0 },
		{ 0, 0, 0, 1 }
	    }, 16 * sizeof(float)),
	    0);
}

- (void)testDescription
{
	OTAssertEqualObjects(_matrix.description,
	    @"<OFMatrix4x4: {\n"
	    @"\t1 2 3 4\n"
	    @"\t5 6 7 8\n"
	    @"\t9 10 11 12\n"
	    @"\t13 14 15 16\n"
	    @"}>");
}

- (void)testIsEqual
{
	OTAssertEqualObjects([OFMatrix4x4 identityMatrix],
	    ([OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{ 1, 0, 0, 0 },
		{ 0, 1, 0, 0 },
		{ 0, 0, 1, 0 },
		{ 0, 0, 0, 1 }
	    }]));
}

- (void)testHash
{
	OTAssertEqual([[OFMatrix4x4 identityMatrix] hash],
	    [([OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{ 1, 0, 0, 0 },
		{ 0, 1, 0, 0 },
		{ 0, 0, 1, 0 },
		{ 0, 0, 0, 1 }
	    }]) hash]);
}

- (void)testCopy
{
	OTAssertEqualObjects(objc_autorelease([_matrix copy]), _matrix);
}

- (void)testMultiplyWithMatrix
{
	OFMatrix4x4 *matrix;

	matrix = objc_autorelease([_matrix copy]);
	[matrix multiplyWithMatrix: [OFMatrix4x4 identityMatrix]];
	OTAssertEqualObjects(matrix, _matrix);

	matrix = [OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{  100,  200,  300,  400 },
		{  500,  600,  700,  800 },
		{  900, 1000, 1100, 1200 },
		{ 1300, 1400, 1500, 1600 }
	}];
	[matrix multiplyWithMatrix: _matrix];
	OTAssertEqualObjects(matrix,
	    ([OFMatrix4x4 matrixWithValues: (const float [4][4]){
		{  9000, 10000, 11000, 12000 },
		{ 20200, 22800, 25400, 28000 },
		{ 31400, 35600, 39800, 44000 },
		{ 42600, 48400, 54200, 60000 }
	    }]));
}

- (void)testTranslateWithVector
{
	OFMatrix4x4 *matrix = [OFMatrix4x4 identityMatrix];
	OFVector4D point;

	[matrix translateWithVector: OFMakeVector3D(1, 2, 3)];

	point = [matrix transformedVector: OFMakeVector4D(2, 3, 4, 1)];
	OTAssertEqual(point.x, 3);
	OTAssertEqual(point.y, 5);
	OTAssertEqual(point.z, 7);
	OTAssertEqual(point.w, 1);
}

- (void)testScaleWithVector
{
	OFMatrix4x4 *matrix = [OFMatrix4x4 identityMatrix];
	OFVector4D point;

	[matrix translateWithVector: OFMakeVector3D(1, 2, 3)];
	[matrix scaleWithVector: OFMakeVector3D(-1, 0.5f, 2)];

	point = [matrix transformedVector: OFMakeVector4D(2, 3, 4, 1)];
	OTAssertEqual(point.x, -3);
	OTAssertEqual(point.y, 2.5);
	OTAssertEqual(point.z, 14);
	OTAssertEqual(point.w, 1);
}

- (void)testTransformVectorsCount
{
	OF_ALIGN(16) OFVector4D points[2] = {{ 1, 2, 3, 1 }, { 7, 8, 9, 2 }};

	[_matrix transformVectors: points count: 2];

	OTAssertEqual(points[0].x, 18);
	OTAssertEqual(points[0].y, 46);
	OTAssertEqual(points[0].z, 74);
	OTAssertEqual(points[0].w, 102);
	OTAssertEqual(points[1].x, 58);
	OTAssertEqual(points[1].y, 162);
	OTAssertEqual(points[1].z, 266);
	OTAssertEqual(points[1].w, 370);
}
@end
