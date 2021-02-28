/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

static OFString *module = @"OFWindowsRegistryKey";

@implementation TestsAppDelegate (OFWindowsRegistryKeyTests)
- (void)windowsRegistryKeyTests
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithItems: "abcdef"
				       count: 6];
	OFWindowsRegistryKey *softwareKey, *ObjFWKey;
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

	TEST(@"-[openSubkeyAtPath:securityAndAccessRights:]",
	    (softwareKey = [[OFWindowsRegistryKey currentUserKey]
		   openSubkeyAtPath: @"Software"
	    securityAndAccessRights: KEY_ALL_ACCESS]) &&
	    [[OFWindowsRegistryKey currentUserKey]
		   openSubkeyAtPath: @"nonexistent"
	    securityAndAccessRights: KEY_ALL_ACCESS] == nil)

	TEST(@"-[createSubkeyAtPath:securityAndAccessRights:]",
	    (ObjFWKey = [softwareKey createSubkeyAtPath: @"ObjFW"
				securityAndAccessRights: KEY_ALL_ACCESS]))

	TEST(@"-[setData:forValueNamed:type:]",
	    R([ObjFWKey setData: data
		  forValueNamed: @"data"
			   type: REG_BINARY]))

	TEST(@"-[dataForValueNamed:subkeyPath:flags:type:]",
	    [[ObjFWKey dataForValueNamed: @"data"
				    type: &type] isEqual: data] &&
	    type == REG_BINARY)

	TEST(@"-[setString:forValueNamed:type:]",
	    R([ObjFWKey setString: @"foobar"
		    forValueNamed: @"string"]) &&
	    R([ObjFWKey setString: @"%PATH%;foo"
		    forValueNamed: @"expand"
			     type: REG_EXPAND_SZ]))

	TEST(@"-[stringForValue:subkeyPath:]",
	    [[ObjFWKey stringForValueNamed: @"string"] isEqual: @"foobar"] &&
	    [[ObjFWKey stringForValueNamed: @"expand"
				      type: &type] isEqual: @"%PATH%;foo"] &&
	    type == REG_EXPAND_SZ)

	TEST(@"-[deleteValueNamed:]", R([ObjFWKey deleteValueNamed: @"data"]))

	TEST(@"-[deleteSubkeyAtPath:]",
	    R([softwareKey deleteSubkeyAtPath: @"ObjFW"]))

	objc_autoreleasePoolPop(pool);
}
@end
