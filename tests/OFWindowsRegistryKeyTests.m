/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

	_softwareKey = [[[OFWindowsRegistryKey currentUserKey]
	    openSubkeyAtPath: @"Software"
		accessRights: KEY_ALL_ACCESS
		     options: 0] retain];
	_objFWKey = [[_softwareKey createSubkeyAtPath: @"ObjFW"
					 accessRights: KEY_ALL_ACCESS
				   securityAttributes: NULL
					      options: 0
					  disposition: NULL] retain];
}

- (void)tearDown
{
	[_softwareKey deleteSubkeyAtPath: @"ObjFW"];

	[super tearDown];
}

- (void)dealloc
{
	[_softwareKey release];
	[_objFWKey release];

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
