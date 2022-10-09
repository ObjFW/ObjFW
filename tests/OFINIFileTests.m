/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

static OFString *module;

@implementation TestsAppDelegate (OFINIFileTests)
- (void)INIFileTests
{
	void *pool = objc_autoreleasePoolPush();
	OFString *output = @"[tests]\r\n"
	    @"foo=baz\r\n"
	    @"foobar=baz\r\n"
	    @";comment\r\n"
	    @"new=new\r\n"
	    @"\r\n"
	    @"[foobar]\r\n"
	    @";foobarcomment\r\n"
	    @"qux=\" asd\"\r\n"
	    @"quxquxqux=\"hello\\\"wörld\"\r\n"
	    @"qux2=\"a\\f\"\r\n"
	    @"qux3=a\fb\r\n"
	    @"\r\n"
	    @"[types]\r\n"
	    @"integer=16\r\n"
	    @"bool=false\r\n"
	    @"float=0.25\r\n"
	    @"array1=foo\r\n"
	    @"array1=bar\r\n"
	    @"double=0.75\r\n";
	OFURI *URI;
	OFINIFile *file;
	OFINICategory *tests, *foobar, *types;
	OFArray *array;
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	OFURI *writeURI;
#endif

	module = @"OFINIFile";

	URI = [OFURI URIWithString: @"embedded:testfile.ini"];
	TEST(@"+[fileWithURI:encoding:]",
	    (file = [OFINIFile fileWithURI: URI
				  encoding: OFStringEncodingCodepage437]))

	tests = [file categoryForName: @"tests"];
	foobar = [file categoryForName: @"foobar"];
	types = [file categoryForName: @"types"];
	TEST(@"-[categoryForName:]",
	    tests != nil && foobar != nil && types != nil)

	module = @"OFINICategory";

	TEST(@"-[stringForKey:]",
	    [[tests stringForKey: @"foo"] isEqual: @"bar"] &&
	    [[foobar stringForKey: @"quxquxqux"] isEqual: @"hello\"wörld"])

	TEST(@"-[setString:forKey:]",
	    R([tests setString: @"baz" forKey: @"foo"]) &&
	    R([tests setString: @"new" forKey: @"new"]) &&
	    R([foobar setString: @"a\fb" forKey: @"qux3"]))

	TEST(@"-[longLongForKey:defaultValue:]",
	    [types longLongForKey: @"integer" defaultValue: 2] == 0x20)

	TEST(@"-[setLongLong:forKey:]",
	    R([types setLongLong: 0x10 forKey: @"integer"]))

	TEST(@"-[boolForKey:defaultValue:]",
	    [types boolForKey: @"bool" defaultValue: false] == true)

	TEST(@"-[setBool:forKey:]", R([types setBool: false forKey: @"bool"]))

	TEST(@"-[floatForKey:defaultValue:]",
	    [types floatForKey: @"float" defaultValue: 1] == 0.5f)

	TEST(@"-[setFloat:forKey:]",
	    R([types setFloat: 0.25f forKey: @"float"]))

	TEST(@"-[doubleForKey:defaultValue:]",
	    [types doubleForKey: @"double" defaultValue: 3] == 0.25)

	TEST(@"-[setDouble:forKey:]",
	    R([types setDouble: 0.75 forKey: @"double"]))

	array = [OFArray arrayWithObjects: @"1", @"2", nil];
	TEST(@"-[stringArrayForKey:]",
	    [[types stringArrayForKey: @"array1"] isEqual: array] &&
	    [[types stringArrayForKey: @"array2"] isEqual: array] &&
	    [[types stringArrayForKey: @"array3"] isEqual: [OFArray array]])

	array = [OFArray arrayWithObjects: @"foo", @"bar", nil];
	TEST(@"-[setStringArray:forKey:]",
	    R([types setStringArray: array forKey: @"array1"]))

	TEST(@"-[removeValueForKey:]",
	    R([foobar removeValueForKey: @"quxqux "]) &&
	    R([types removeValueForKey: @"array2"]))

	module = @"OFINIFile";

	/* FIXME: Find a way to write files on Nintendo DS */
#if defined(OF_HAVE_FILES) && !defined(OF_NINTENDO_DS)
	writeURI = [[OFSystemInfo temporaryDirectoryURI]
	    URIByAppendingPathComponent: @"objfw-tests.ini"
			    isDirectory: false];
	TEST(@"-[writeToFile:encoding:]",
	    R([file writeToURI: writeURI
		      encoding: OFStringEncodingCodepage437]) &&
	    [[OFString stringWithContentsOfURI: writeURI
				      encoding: OFStringEncodingCodepage437]
	    isEqual: output])
	[[OFFileManager defaultManager] removeItemAtURI: writeURI];
#else
	(void)output;
#endif

	objc_autoreleasePoolPop(pool);
}
@end
