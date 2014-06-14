/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

#ifdef _WIN32
# define NL @"\r\n"
#else
# define NL @"\n"
#endif

static OFString *module = @"OFINIFile";

@implementation TestsAppDelegate (OFINIFileTests)
- (void)INIFileTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *output = @"[tests]" NL
	    @"foo=baz" NL
	    @"foobar=baz" NL
	    @";comment" NL
	    @"new=new" NL
	    NL
	    @"[foobar]" NL
	    @";foobarcomment" NL
	    @"qux=\" asd\"" NL
	    @"quxquxqux=\"hello\\\"wörld\"" NL
	    @"qux2=\"a\\f\"" NL
	    @"qux3=a\fb" NL
	    NL
	    @"[types]" NL
	    @"integer=16" NL
	    @"bool=false" NL
	    @"float=0.25" NL
	    @"double=0.75" NL;
	OFINIFile *file;
	OFINICategory *tests, *foobar, *types;

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

	TEST(@"-[removeValueForKey:]",
	    R([foobar removeValueForKey: @"quxqux "]))

	module = @"OFINIFile";

	/* FIXME: Find a way to write files on Nintendo DS */
#ifndef OF_NINTENDO_DS
	TEST(@"-[writeToFile:encoding:]",
	    R([file writeToFile: @"tmpfile.ini"
		       encoding: OF_STRING_ENCODING_CODEPAGE_437]) &&
	    [[OFString
		stringWithContentsOfFile: @"tmpfile.ini"
				encoding: OF_STRING_ENCODING_CODEPAGE_437]
	    isEqual: output])
	[OFFile removeItemAtPath: @"tmpfile.ini"];
#else
	(void)output;
#endif

	[pool drain];
}
@end
