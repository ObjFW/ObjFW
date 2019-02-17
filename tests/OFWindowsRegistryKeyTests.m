/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFWindowsRegistryKey.h"
#import "OFData.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFWindowsRegistryKey";

@implementation TestsAppDelegate (OFWindowsRegistryKeyTests)
- (void)windowsRegistryKeyTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFData *data = [OFData dataWithItems: "abcdef"
				       count: 6];
	OFWindowsRegistryKey *softwareKey, *ObjFWKey;
	DWORD type;
	OFString *string;

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

	TEST(@"-[setData:forValue:type:]",
	    R([ObjFWKey setData: data
		       forValue: @"data"
			   type: REG_BINARY]))

	TEST(@"-[dataForValue:subkeyPath:flags:type:]",
	    [[softwareKey dataForValue: @"data"
			    subkeyPath: @"ObjFW"
				 flags: RRF_RT_REG_BINARY
				  type: &type] isEqual: data] &&
	    type == REG_BINARY)

	TEST(@"-[setString:forValue:type:]",
	    R([ObjFWKey setString: @"foobar"
			 forValue: @"string"]) &&
	    R([ObjFWKey setString: @"%PATH%;foo"
			 forValue: @"expand"
			     type: REG_EXPAND_SZ]))

	TEST(@"-[stringForValue:subkeyPath:]",
	    [[softwareKey stringForValue: @"string"
			      subkeyPath: @"ObjFW"] isEqual: @"foobar"] &&
	    [[softwareKey stringForValue: @"expand"
			      subkeyPath: @"ObjFW"
				   flags: RRF_RT_REG_EXPAND_SZ | RRF_NOEXPAND
				    type: &type] isEqual: @"%PATH%;foo"] &&
	    type == REG_EXPAND_SZ &&
	    (string = [ObjFWKey stringForValue: @"expand"
				    subkeyPath: nil]) &&
	    ![string isEqual: @"%PATH%;foo"] &&
	    [string hasSuffix: @";foo"])

	TEST(@"-[deleteValue:]", R([ObjFWKey deleteValue: @"data"]))

	TEST(@"-[deleteSubkeyAtPath:]",
	    R([softwareKey deleteSubkeyAtPath: @"ObjFW"]))

	[pool drain];
}
@end
