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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFWindowsRegistryKey";

@implementation TestsAppDelegate (OFWindowsRegistryKeyTests)
- (void)windowsRegistryKeyTests
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithItems: "abcdef" count: 6];
	OFWindowsRegistryKey *softwareKey, *objFWKey;
	DWORD type;

	TEST(@"+[OFWindowsRegistryKey classesRootKey]",
	    [OFWindowsRegistryKey classesRootKey])

	TEST(@"+[OFWindowsRegistryKey currentConfigKey]",
	    [OFWindowsRegistryKey currentConfigKey])

	TEST(@"+[OFWindowsRegistryKey currentUserKey]",
	    [OFWindowsRegistryKey currentUserKey])

	TEST(@"+[OFWindowsRegistryKey localMachineKey]",
	    [OFWindowsRegistryKey localMachineKey])

	TEST(@"+[OFWindowsRegistryKey usersKey]",
	    [OFWindowsRegistryKey usersKey])

	    TEST(@"-[openSubkeyAtPath:accessRights:options:] #1",
	    (softwareKey = [[OFWindowsRegistryKey currentUserKey]
		openSubkeyAtPath: @"Software"
		    accessRights: KEY_ALL_ACCESS
			 options: 0]))

	EXPECT_EXCEPTION(@"-[openSubkeyAtPath:accessRights:options:] #2",
	    OFOpenWindowsRegistryKeyFailedException,
	    [[OFWindowsRegistryKey currentUserKey]
		openSubkeyAtPath: @"nonexistent"
		    accessRights: KEY_ALL_ACCESS
			 options: 0])

	TEST(@"-[createSubkeyAtPath:accessRights:securityAttributes:options:"
	    @"disposition:]",
	    (objFWKey = [softwareKey createSubkeyAtPath: @"ObjFW"
					   accessRights: KEY_ALL_ACCESS
				     securityAttributes: NULL
						options: 0
					    disposition: NULL]))

	TEST(@"-[setData:forValueNamed:type:]",
	    R([objFWKey setData: data forValueNamed: @"data" type: REG_BINARY]))

	TEST(@"-[dataForValueNamed:subkeyPath:flags:type:]",
	    [[objFWKey dataForValueNamed: @"data" type: &type] isEqual: data] &&
	    type == REG_BINARY)

	TEST(@"-[setString:forValueNamed:type:]",
	    R([objFWKey setString: @"foobar" forValueNamed: @"string"]) &&
	    R([objFWKey setString: @"%PATH%;foo"
		    forValueNamed: @"expand"
			     type: REG_EXPAND_SZ]))

	TEST(@"-[stringForValue:subkeyPath:]",
	    [[objFWKey stringForValueNamed: @"string"] isEqual: @"foobar"] &&
	    [[objFWKey stringForValueNamed: @"expand" type: &type]
	    isEqual: @"%PATH%;foo"] &&
	    type == REG_EXPAND_SZ)

	TEST(@"-[deleteValueNamed:]", R([objFWKey deleteValueNamed: @"data"]))

	TEST(@"-[deleteSubkeyAtPath:]",
	    R([softwareKey deleteSubkeyAtPath: @"ObjFW"]))

	objc_autoreleasePoolPop(pool);
}
@end
