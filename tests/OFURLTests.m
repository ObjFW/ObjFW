/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFURL.h"
#import "OFArray.h"
#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
#endif
#import "OFNumber.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidFormatException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFURL";
static OFString *url_str = @"ht%3atp://us%3Aer:p%40w@ho%3Ast:1234/"
    @"pa%3Fth?que%23ry#frag%23ment";

@implementation TestsAppDelegate (OFURLTests)
- (void)URLTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFURL *u1, *u2, *u3, *u4;
	OFMutableURL *mu;

	TEST(@"+[URLWithString:]",
	    R(u1 = [OFURL URLWithString: url_str]) &&
	    R(u2 = [OFURL URLWithString: @"http://foo:80"]) &&
	    R(u3 = [OFURL URLWithString: @"http://bar/"]) &&
	    R(u4 = [OFURL URLWithString: @"file:///etc/passwd"]))

	TEST(@"+[URLWithString:relativeToURL:]",
	    [[[OFURL URLWithString: @"/foo"
		     relativeToURL: u1] string] isEqual:
	    @"ht%3atp://us%3Aer:p%40w@ho%3Ast:1234/foo"] &&
	    [[[OFURL URLWithString: @"foo/bar?q"
		     relativeToURL: [OFURL URLWithString: @"http://h/qux/quux"]]
	    string] isEqual: @"http://h/qux/foo/bar?q"] &&
	    [[[OFURL URLWithString: @"foo/bar"
		     relativeToURL: [OFURL URLWithString: @"http://h/qux/?x"]]
	    string] isEqual: @"http://h/qux/foo/bar"] &&
	    [[[OFURL URLWithString: @"http://foo/?q"
		     relativeToURL: u1] string] isEqual: @"http://foo/?q"])

#ifdef OF_HAVE_FILES
	TEST(@"+[fileURLWithPath:isDirectory:]",
	    [[[OFURL fileURLWithPath: @"testfile.txt"] fileSystemRepresentation]
	    isEqual: [[[OFFileManager defaultManager] currentDirectoryPath]
	    stringByAppendingPathComponent: @"testfile.txt"]])
#endif

	TEST(@"-[string]",
	    [[u1 string] isEqual: url_str] &&
	    [[u2 string] isEqual: @"http://foo:80"] &&
	    [[u3 string] isEqual: @"http://bar/"] &&
	    [[u4 string] isEqual: @"file:///etc/passwd"])

	TEST(@"-[scheme]",
	    [[u1 scheme] isEqual: @"ht:tp"] && [[u4 scheme] isEqual: @"file"])

	TEST(@"-[user]", [[u1 user] isEqual: @"us:er"] && [u4 user] == nil)
	TEST(@"-[password]",
	    [[u1 password] isEqual: @"p@w"] && [u4 password] == nil)
	TEST(@"-[host]", [[u1 host] isEqual: @"ho:st"] && [u4 port] == 0)
	TEST(@"-[port]", [[u1 port] isEqual: [OFNumber numberWithUInt16: 1234]])
	TEST(@"-[path]",
	    [[u1 path] isEqual: @"/pa?th"] &&
	    [[u4 path] isEqual: @"/etc/passwd"])
	TEST(@"-[pathComponents]",
	    [[u1 pathComponents] isEqual:
	    [OFArray arrayWithObjects: @"", @"pa?th", nil]] &&
	    [[u4 pathComponents] isEqual:
	    [OFArray arrayWithObjects: @"", @"etc", @"passwd", nil]])
	TEST(@"-[lastPathComponent",
	    [[[OFURL URLWithString: @"http://host/foo//bar/baz"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFURL URLWithString: @"http://host/foo//bar/baz/"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFURL URLWithString: @"http://host/foo/"]
	    lastPathComponent] isEqual: @"foo"] &&
	    [[[OFURL URLWithString: @"http://host/"]
	    lastPathComponent] isEqual: @""])
	TEST(@"-[query]",
	    [[u1 query] isEqual: @"que#ry"] && [u4 query] == nil)
	TEST(@"-[fragment]",
	    [[u1 fragment] isEqual: @"frag#ment"] && [u4 fragment] == nil)

	TEST(@"-[copy]", R(u4 = [[u1 copy] autorelease]))

	TEST(@"-[isEqual:]", [u1 isEqual: u4] && ![u2 isEqual: u3] &&
	    [[OFURL URLWithString: @"HTTP://bar/"] isEqual: u3])

	TEST(@"-[hash:]", [u1 hash] == [u4 hash] && [u2 hash] != [u3 hash])

	EXPECT_EXCEPTION(@"Detection of invalid format",
	    OFInvalidFormatException, [OFURL URLWithString: @"http"])

	mu = [OFMutableURL URL];

	TEST(@"-[setScheme:]",
	    R([mu setScheme: @"ht:tp"]) &&
	    [[mu URLEncodedScheme] isEqual: @"ht%3Atp"])

	TEST(@"-[setHost:]",
	    R([mu setHost: @"ho:st"]) &&
	    [[mu URLEncodedHost] isEqual: @"ho%3Ast"])

	TEST(@"-[setUser:]",
	    R([mu setUser: @"us:er"]) &&
	    [[mu URLEncodedUser] isEqual: @"us%3Aer"])

	TEST(@"-[setPassword:]",
	    R([mu setPassword: @"pass:word"]) &&
	    [[mu URLEncodedPassword] isEqual: @"pass%3Aword"])

	TEST(@"-[setPath:]",
	    R([mu setPath: @"pa/th@?"]) &&
	    [[mu URLEncodedPath] isEqual: @"pa/th@%3F"])

	TEST(@"-[setQuery:]",
	    R([mu setQuery: @"que/ry?#"]) &&
	    [[mu URLEncodedQuery] isEqual: @"que/ry?%23"])

	TEST(@"-[setFragment:]",
	    R([mu setFragment: @"frag/ment?#"]) &&
	    [[mu URLEncodedFragment] isEqual: @"frag/ment?%23"])

	[pool drain];
}
@end
