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

@interface OFWindowsRegistryKeyTests: OTTestCase
{
	OFWindowsRegistryKey *_softwareKey, *_objFWKey;
}
@end

@implementation OFWindowsRegistryKeyTests
- (void)setUp
{
	[super setUp];

	_softwareKey = objc_retain([[OFWindowsRegistryKey currentUserKey]
	    openSubkeyAtPath: @"Software"
		accessRights: KEY_ALL_ACCESS
		     options: 0]);
	_objFWKey = objc_retain([_softwareKey createSubkeyAtPath: @"ObjFW"
						    accessRights: KEY_ALL_ACCESS
					      securityAttributes: NULL
							 options: 0
						     disposition: NULL]);
}

- (void)tearDown
{
	[_softwareKey deleteSubkeyAtPath: @"ObjFW"];

	[super tearDown];
}

- (void)dealloc
{
	objc_release(_softwareKey);
	objc_release(_objFWKey);

	[super dealloc];
}

- (void)testClassesRootKey
{
	OTAssertEqual([[OFWindowsRegistryKey classesRootKey] class],
	    [OFWindowsRegistryKey class]);
}

- (void)testCurrentConfigKey
{
	OTAssertEqual([[OFWindowsRegistryKey currentConfigKey] class],
	    [OFWindowsRegistryKey class]);
}

- (void)testCurrentUserKey
{
	OTAssertEqual([[OFWindowsRegistryKey currentUserKey] class],
	    [OFWindowsRegistryKey class]);
}

- (void)testLocalMachineKey
{
	OTAssertEqual([[OFWindowsRegistryKey localMachineKey] class],
	    [OFWindowsRegistryKey class]);
}

- (void)testOpenSubkeyAtPathAccessRightsOptionsThrowsForNonExistentKey
{
	OTAssertThrowsSpecific([[OFWindowsRegistryKey currentUserKey]
	    openSubkeyAtPath: @"nonexistent"
		accessRights: KEY_ALL_ACCESS
		     options: 0], OFOpenWindowsRegistryKeyFailedException);
}

- (void)testSetAndGetData
{
	OFData *data = [OFData dataWithItems: "abcdef" count: 6];
	DWORD type;

	[_objFWKey setData: data forValueNamed: @"data" type: REG_BINARY];
	OTAssertEqualObjects([_objFWKey dataForValueNamed: @"data" type: &type],
	    data);
	OTAssertEqual(type, REG_BINARY);
}

- (void)testSetAndGetString
{
	DWORD type;

	[_objFWKey setString: @"foobar" forValueNamed: @"string"];
	OTAssertEqualObjects([_objFWKey stringForValueNamed: @"string"],
	    @"foobar");

	[_objFWKey setString: @"%PATH%;foo"
	       forValueNamed: @"expand"
			type: REG_EXPAND_SZ];
	OTAssertEqualObjects([_objFWKey stringForValueNamed: @"expand"
						       type: &type],
	    @"%PATH%;foo");
	OTAssertEqual(type, REG_EXPAND_SZ);
}

- (void)testDeleteValue
{
	[_objFWKey setString: @"foobar" forValueNamed: @"deleteme"];
	OTAssertEqualObjects([_objFWKey stringForValueNamed: @"deleteme"],
	    @"foobar");

	[_objFWKey deleteValueNamed: @"deleteme"];
	OTAssertNil([_objFWKey stringForValueNamed: @"deleteme"]);
}
@end
