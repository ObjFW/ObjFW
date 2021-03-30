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

static OFString *module = @"OFURL";
static OFString *url_str = @"ht%3atp://us%3Aer:p%40w@ho%3Ast:1234/"
    @"pa%3Fth?que%23ry=1&f%26oo=b%3dar#frag%23ment";

@implementation TestsAppDelegate (OFURLTests)
- (void)URLTests
{
	void *pool = objc_autoreleasePoolPush();
	OFURL *u1, *u2, *u3, *u4, *u5, *u6, *u7;
	OFMutableURL *mu;

	TEST(@"+[URLWithString:]",
	    R(u1 = [OFURL URLWithString: url_str]) &&
	    R(u2 = [OFURL URLWithString: @"http://foo:80"]) &&
	    R(u3 = [OFURL URLWithString: @"http://bar/"]) &&
	    R(u4 = [OFURL URLWithString: @"file:///etc/passwd"]) &&
	    R(u5 = [OFURL URLWithString: @"http://foo/bar/qux/foo%2fbar"]) &&
	    R(u6 = [OFURL URLWithString: @"https://[12:34::56:abcd]/"]) &&
	    R(u7 = [OFURL URLWithString: @"https://[12:34::56:abcd]:234/"]))

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"ht,tp://foo"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"http://f`oo"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"http://foo/`"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"http://foo/foo?`"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #5",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"http://foo/foo?foo#`"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #6",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"https://[g]/"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #7",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"https://[f]:/"])

	EXPECT_EXCEPTION(@"+[URLWithString:] fails with invalid characters #8",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"https://[f]:f/"])

	TEST(@"+[URLWithString:relativeToURL:]",
	    [[[OFURL URLWithString: @"/foo" relativeToURL: u1] string] isEqual:
	    @"ht%3atp://us%3Aer:p%40w@ho%3Ast:1234/foo"] &&
	    [[[OFURL URLWithString: @"foo/bar?q"
		     relativeToURL: [OFURL URLWithString: @"http://h/qux/quux"]]
	    string] isEqual: @"http://h/qux/foo/bar?q"] &&
	    [[[OFURL URLWithString: @"foo/bar"
		     relativeToURL: [OFURL URLWithString: @"http://h/qux/?x"]]
	    string] isEqual: @"http://h/qux/foo/bar"] &&
	    [[[OFURL URLWithString: @"http://foo/?q"
		     relativeToURL: u1] string] isEqual: @"http://foo/?q"] &&
	    [[[OFURL URLWithString: @"foo"
		     relativeToURL: [OFURL URLWithString: @"http://foo/bar"]]
	    string] isEqual: @"http://foo/foo"] &&
	    [[[OFURL URLWithString: @"foo"
		     relativeToURL: [OFURL URLWithString: @"http://foo"]]
	    string] isEqual: @"http://foo/foo"])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"`" relativeToURL: u1])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"/`" relativeToURL: u1])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"?`" relativeToURL: u1])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"#`" relativeToURL: u1])

#ifdef OF_HAVE_FILES
	TEST(@"+[fileURLWithPath:]",
	    [[[OFURL fileURLWithPath: @"testfile.txt"] fileSystemRepresentation]
	    isEqual: [[OFFileManager defaultManager].currentDirectoryPath
	    stringByAppendingPathComponent: @"testfile.txt"]])

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OFURL *tmp;
	TEST(@"+[fileURLWithPath:] for c:\\",
	    (tmp = [OFURL fileURLWithPath: @"c:\\"]) &&
	    [tmp.string isEqual: @"file:///c:/"] &&
	    [tmp.fileSystemRepresentation isEqual: @"c:\\"])
# endif

# ifdef OF_WINDOWS
	TEST(@"+[fileURLWithPath:] with UNC",
	    (tmp = [OFURL fileURLWithPath: @"\\\\foo\\bar"]) &&
	    [tmp.host isEqual: @"foo"] && [tmp.path isEqual: @"/bar"] &&
	    [tmp.string isEqual: @"file://foo/bar"] &&
	    [tmp.fileSystemRepresentation isEqual: @"\\\\foo\\bar"] &&
	    (tmp = [OFURL fileURLWithPath: @"\\\\test"]) &&
	    [tmp.host isEqual: @"test"] && [tmp.path isEqual: @"/"] &&
	    [tmp.string isEqual: @"file://test/"] &&
	    [tmp.fileSystemRepresentation isEqual: @"\\\\test"])
# endif
#endif

	TEST(@"-[string]",
	    [u1.string isEqual: url_str] &&
	    [u2.string isEqual: @"http://foo:80"] &&
	    [u3.string isEqual: @"http://bar/"] &&
	    [u4.string isEqual: @"file:///etc/passwd"])

	TEST(@"-[scheme]",
	    [u1.scheme isEqual: @"ht:tp"] && [u4.scheme isEqual: @"file"])

	TEST(@"-[user]", [u1.user isEqual: @"us:er"] && u4.user == nil)
	TEST(@"-[password]",
	    [u1.password isEqual: @"p@w"] && u4.password == nil)
	TEST(@"-[host]", [u1.host isEqual: @"ho:st"] &&
	    [u6.host isEqual: @"12:34::56:abcd"] &&
	    [u7.host isEqual: @"12:34::56:abcd"])
	TEST(@"-[port]", u1.port.unsignedShortValue == 1234 &&
	    [u4 port] == nil && u7.port.unsignedShortValue == 234)
	TEST(@"-[path]",
	    [u1.path isEqual: @"/pa?th"] && [u4.path isEqual: @"/etc/passwd"])
	TEST(@"-[pathComponents]",
	    [u1.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"pa?th", nil]] &&
	    [u4.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"etc", @"passwd", nil]] &&
	    [u5.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"bar", @"qux", @"foo/bar", nil]])
	TEST(@"-[lastPathComponent]",
	    [[[OFURL URLWithString: @"http://host/foo//bar/baz"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFURL URLWithString: @"http://host/foo//bar/baz/"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFURL URLWithString: @"http://host/foo/"]
	    lastPathComponent] isEqual: @"foo"] &&
	    [[[OFURL URLWithString: @"http://host/"]
	    lastPathComponent] isEqual: @"/"] &&
	    [u5.lastPathComponent isEqual: @"foo/bar"])
	TEST(@"-[query]",
	    [u1.query isEqual: @"que#ry=1&f&oo=b=ar"] && u4.query == nil)
	TEST(@"-[queryDictionary]",
	    [u1.queryDictionary isEqual:
	    [OFDictionary dictionaryWithKeysAndObjects:
	    @"que#ry", @"1", @"f&oo", @"b=ar", nil]]);
	TEST(@"-[fragment]",
	    [u1.fragment isEqual: @"frag#ment"] && u4.fragment == nil)

	TEST(@"-[copy]", R(u4 = [[u1 copy] autorelease]))

	TEST(@"-[isEqual:]", [u1 isEqual: u4] && ![u2 isEqual: u3] &&
	    [[OFURL URLWithString: @"HTTP://bar/"] isEqual: u3])

	TEST(@"-[hash:]", u1.hash == u4.hash && u2.hash != u3.hash)

	EXPECT_EXCEPTION(@"Detection of invalid format",
	    OFInvalidFormatException, [OFURL URLWithString: @"http"])

	mu = [OFMutableURL URL];

	TEST(@"-[setScheme:]",
	    (mu.scheme = @"ht:tp") && [mu.URLEncodedScheme isEqual: @"ht%3Atp"])

	TEST(@"-[setURLEncodedScheme:]",
	    (mu.URLEncodedScheme = @"ht%3Atp") && [mu.scheme isEqual: @"ht:tp"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedScheme:] with invalid characters fails",
	    OFInvalidFormatException, mu.URLEncodedScheme = @"~")

	TEST(@"-[setHost:]",
	    (mu.host = @"ho:st") && [mu.URLEncodedHost isEqual: @"ho%3Ast"] &&
	    (mu.host = @"12:34:ab") &&
	    [mu.URLEncodedHost isEqual: @"[12:34:ab]"] &&
	    (mu.host = @"12:34:aB") &&
	    [mu.URLEncodedHost isEqual: @"[12:34:aB]"] &&
	    (mu.host = @"12:34:g") &&
	    [mu.URLEncodedHost isEqual: @"12%3A34%3Ag"])

	TEST(@"-[setURLEncodedHost:]",
	    (mu.URLEncodedHost = @"ho%3Ast") && [mu.host isEqual: @"ho:st"] &&
	    (mu.URLEncodedHost = @"[12:34]") && [mu.host isEqual: @"12:34"] &&
	    (mu.URLEncodedHost = @"[12::ab]") && [mu.host isEqual: @"12::ab"])

	EXPECT_EXCEPTION(@"-[setURLEncodedHost:] with invalid characters fails"
	    " #1", OFInvalidFormatException, mu.URLEncodedHost = @"/")

	EXPECT_EXCEPTION(@"-[setURLEncodedHost:] with invalid characters fails"
	    " #2", OFInvalidFormatException, mu.URLEncodedHost = @"[12:34")

	EXPECT_EXCEPTION(@"-[setURLEncodedHost:] with invalid characters fails"
	    " #3", OFInvalidFormatException, mu.URLEncodedHost = @"[a::g]")

	TEST(@"-[setUser:]",
	    (mu.user = @"us:er") && [mu.URLEncodedUser isEqual: @"us%3Aer"])

	TEST(@"-[setURLEncodedUser:]",
	    (mu.URLEncodedUser = @"us%3Aer") && [mu.user isEqual: @"us:er"])

	EXPECT_EXCEPTION(@"-[setURLEncodedUser:] with invalid characters fails",
	    OFInvalidFormatException, mu.URLEncodedHost = @"/")

	TEST(@"-[setPassword:]",
	    (mu.password = @"pass:word") &&
	    [mu.URLEncodedPassword isEqual: @"pass%3Aword"])

	TEST(@"-[setURLEncodedPassword:]",
	    (mu.URLEncodedPassword = @"pass%3Aword") &&
	    [mu.password isEqual: @"pass:word"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedPassword:] with invalid characters fails",
	    OFInvalidFormatException, mu.URLEncodedPassword = @"/")

	TEST(@"-[setPath:]",
	    (mu.path = @"pa/th@?") && [mu.URLEncodedPath isEqual: @"pa/th@%3F"])

	TEST(@"-[setURLEncodedPath:]",
	    (mu.URLEncodedPath = @"pa/th@%3F") && [mu.path isEqual: @"pa/th@?"])

	EXPECT_EXCEPTION(@"-[setURLEncodedPath:] with invalid characters fails",
	    OFInvalidFormatException, mu.URLEncodedPath = @"?")

	TEST(@"-[setQuery:]",
	    (mu.query = @"que/ry?#") &&
	    [mu.URLEncodedQuery isEqual: @"que/ry?%23"])

	TEST(@"-[setURLEncodedQuery:]",
	    (mu.URLEncodedQuery = @"que/ry?%23") &&
	    [mu.query isEqual: @"que/ry?#"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedQuery:] with invalid characters fails",
	    OFInvalidFormatException, mu.URLEncodedQuery = @"`")

	TEST(@"-[setQueryDictionary:]",
	    (mu.queryDictionary = [OFDictionary dictionaryWithKeysAndObjects:
	    @"foo&bar", @"baz=qux", @"f=oobar", @"b&azqux", nil]) &&
	    [mu.URLEncodedQuery isEqual:
	    @"foo%26bar=baz%3Dqux&f%3Doobar=b%26azqux"])

	TEST(@"-[setFragment:]",
	    (mu.fragment = @"frag/ment?#") &&
	    [mu.URLEncodedFragment isEqual: @"frag/ment?%23"])

	TEST(@"-[setURLEncodedFragment:]",
	    (mu.URLEncodedFragment = @"frag/ment?%23") &&
	    [mu.fragment isEqual: @"frag/ment?#"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedFragment:] with invalid characters fails",
	    OFInvalidFormatException, mu.URLEncodedFragment = @"`")

	TEST(@"-[URLByAppendingPathComponent:isDirectory:]",
	    [[[OFURL URLWithString: @"file:///foo/bar"]
	    URLByAppendingPathComponent: @"qux" isDirectory: false] isEqual:
	    [OFURL URLWithString: @"file:///foo/bar/qux"]] &&
	    [[[OFURL URLWithString: @"file:///foo/bar/"]
	    URLByAppendingPathComponent: @"qux" isDirectory: false] isEqual:
	    [OFURL URLWithString: @"file:///foo/bar/qux"]] &&
	    [[[OFURL URLWithString: @"file:///foo/bar/"]
	    URLByAppendingPathComponent: @"qu?x" isDirectory: false] isEqual:
	    [OFURL URLWithString: @"file:///foo/bar/qu%3Fx"]] &&
	    [[[OFURL URLWithString: @"file:///foo/bar/"]
	    URLByAppendingPathComponent: @"qu?x" isDirectory: true] isEqual:
	    [OFURL URLWithString: @"file:///foo/bar/qu%3Fx/"]])

	TEST(@"-[URLByStandardizingPath]",
	    [[[OFURL URLWithString: @"http://foo/bar/.."]
	    URLByStandardizingPath] isEqual:
	    [OFURL URLWithString: @"http://foo/"]] &&
	    [[[OFURL URLWithString: @"http://foo/bar/%2E%2E/../qux/"]
	    URLByStandardizingPath] isEqual:
	    [OFURL URLWithString: @"http://foo/bar/qux/"]] &&
	    [[[OFURL URLWithString: @"http://foo/bar/./././qux/./"]
	    URLByStandardizingPath] isEqual:
	    [OFURL URLWithString: @"http://foo/bar/qux/"]] &&
	    [[[OFURL URLWithString: @"http://foo/bar/../../qux"]
	    URLByStandardizingPath] isEqual:
	    [OFURL URLWithString: @"http://foo/../qux"]])

	objc_autoreleasePoolPop(pool);
}
@end
