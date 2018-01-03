/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFINIFile.h"
#import "OFINICategory.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFINIFile";

@implementation TestsAppDelegate (OFINIFileTests)
- (void)INIFileTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
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
	OFINIFile *file;
	OFINICategory *tests, *foobar, *types;
	OFArray *array;
#ifndef OF_NINTENDO_DS
	OFString *writePath;
#endif

	TEST(@"+[fileWithPath:encoding:]",
	    (file = [OFINIFile fileWithPath: @"testfile.ini"
				   encoding: OF_STRING_ENCODING_CODEPAGE_437]))

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
	    R([tests setString: @"baz"
			forKey: @"foo"]) &&
	    R([tests setString: @"new"
			forKey: @"new"]) &&
	    R([foobar setString: @"a\fb"
			 forKey: @"qux3"]))

	TEST(@"-[integerForKey:defaultValue:]",
	    [types integerForKey: @"integer"
		    defaultValue: 2] == 0x20)

	TEST(@"-[setInteger:forKey:]", R([types setInteger: 0x10
						    forKey: @"integer"]))

	TEST(@"-[boolForKey:defaultValue:]",
	    [types boolForKey: @"bool"
		 defaultValue: false] == true)

	TEST(@"-[setBool:forKey:]", R([types setBool: false
					      forKey: @"bool"]))

	TEST(@"-[floatForKey:defaultValue:]",
	    [types floatForKey: @"float"
		  defaultValue: 1] == 0.5f)

	TEST(@"-[setFloat:forKey:]", R([types setFloat: 0.25f
						forKey: @"float"]))

	TEST(@"-[doubleForKey:defaultValue:]",
	    [types doubleForKey: @"double"
		   defaultValue: 3] == 0.25)

	TEST(@"-[setDouble:forKey:]", R([types setDouble: 0.75
						  forKey: @"double"]))

	array = [OFArray arrayWithObjects: @"1", @"2", nil];
	TEST(@"-[arrayForKey:]",
	    [[types arrayForKey: @"array1"] isEqual: array] &&
	    [[types arrayForKey: @"array2"] isEqual: array] &&
	    [[types arrayForKey: @"array3"] isEqual: [OFArray array]])

	array = [OFArray arrayWithObjects: @"foo", @"bar", nil];
	TEST(@"-[setArray:forKey:]", R([types setArray: array
						forKey: @"array1"]))

	TEST(@"-[removeValueForKey:]",
	    R([foobar removeValueForKey: @"quxqux "]) &&
	    R([types removeValueForKey: @"array2"]))

	module = @"OFINIFile";

	/* FIXME: Find a way to write files on Nintendo DS */
#ifndef OF_NINTENDO_DS
# ifndef OF_IOS
	writePath = @"tmpfile.ini";
# else
	writePath = [OFString pathWithComponents: [OFArray arrayWithObjects:
	    [[OFApplication environment] objectForKey: @"HOME"],
	    @"tmp", @"tmpfile.ini", nil]];
# endif
	TEST(@"-[writeToFile:encoding:]",
	    R([file writeToFile: writePath
		       encoding: OF_STRING_ENCODING_CODEPAGE_437]) &&
	    [[OFString
		stringWithContentsOfFile: writePath
				encoding: OF_STRING_ENCODING_CODEPAGE_437]
	    isEqual: output])
	[[OFFileManager defaultManager] removeItemAtPath: writePath];
#else
	(void)output;
#endif

	[pool drain];
}
@end
