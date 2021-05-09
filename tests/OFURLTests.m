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

static OFString *const module = @"OFURL";
static OFString *URLString = @"ht%3atp://us%3Aer:p%40w@ho%3Ast:1234/"
    @"pa%3Fth?que%23ry=1&f%26oo=b%3dar#frag%23ment";

@implementation TestsAppDelegate (OFURLTests)
- (void)URLTests
{
	void *pool = objc_autoreleasePoolPush();
	OFURL *URL1, *URL2, *URL3, *URL4, *URL5, *URL6, *URL7;
	OFMutableURL *mutableURL;

	TEST(@"+[URLWithString:]",
	    R(URL1 = [OFURL URLWithString: URLString]) &&
	    R(URL2 = [OFURL URLWithString: @"http://foo:80"]) &&
	    R(URL3 = [OFURL URLWithString: @"http://bar/"]) &&
	    R(URL4 = [OFURL URLWithString: @"file:///etc/passwd"]) &&
	    R(URL5 = [OFURL URLWithString: @"http://foo/bar/qux/foo%2fbar"]) &&
	    R(URL6 = [OFURL URLWithString: @"https://[12:34::56:abcd]/"]) &&
	    R(URL7 = [OFURL URLWithString: @"https://[12:34::56:abcd]:234/"]))

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
	    [[[OFURL URLWithString: @"/foo" relativeToURL: URL1] string]
	    isEqual: @"ht%3atp://us%3Aer:p%40w@ho%3Ast:1234/foo"] &&
	    [[[OFURL URLWithString: @"foo/bar?q"
		     relativeToURL: [OFURL URLWithString: @"http://h/qux/quux"]]
	    string] isEqual: @"http://h/qux/foo/bar?q"] &&
	    [[[OFURL URLWithString: @"foo/bar"
		     relativeToURL: [OFURL URLWithString: @"http://h/qux/?x"]]
	    string] isEqual: @"http://h/qux/foo/bar"] &&
	    [[[OFURL URLWithString: @"http://foo/?q"
		     relativeToURL: URL1] string] isEqual: @"http://foo/?q"] &&
	    [[[OFURL URLWithString: @"foo"
		     relativeToURL: [OFURL URLWithString: @"http://foo/bar"]]
	    string] isEqual: @"http://foo/foo"] &&
	    [[[OFURL URLWithString: @"foo"
		     relativeToURL: [OFURL URLWithString: @"http://foo"]]
	    string] isEqual: @"http://foo/foo"])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"`" relativeToURL: URL1])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"/`" relativeToURL: URL1])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"?`" relativeToURL: URL1])

	EXPECT_EXCEPTION(
	    @"+[URLWithString:relativeToURL:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFURL URLWithString: @"#`" relativeToURL: URL1])

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
	    [URL1.string isEqual: URLString] &&
	    [URL2.string isEqual: @"http://foo:80"] &&
	    [URL3.string isEqual: @"http://bar/"] &&
	    [URL4.string isEqual: @"file:///etc/passwd"])

	TEST(@"-[scheme]",
	    [URL1.scheme isEqual: @"ht:tp"] && [URL4.scheme isEqual: @"file"])

	TEST(@"-[user]", [URL1.user isEqual: @"us:er"] && URL4.user == nil)
	TEST(@"-[password]",
	    [URL1.password isEqual: @"p@w"] && URL4.password == nil)
	TEST(@"-[host]", [URL1.host isEqual: @"ho:st"] &&
	    [URL6.host isEqual: @"12:34::56:abcd"] &&
	    [URL7.host isEqual: @"12:34::56:abcd"])
	TEST(@"-[port]", URL1.port.unsignedShortValue == 1234 &&
	    [URL4 port] == nil && URL7.port.unsignedShortValue == 234)
	TEST(@"-[path]",
	    [URL1.path isEqual: @"/pa?th"] &&
	    [URL4.path isEqual: @"/etc/passwd"])
	TEST(@"-[pathComponents]",
	    [URL1.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"pa?th", nil]] &&
	    [URL4.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"etc", @"passwd", nil]] &&
	    [URL5.pathComponents isEqual:
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
	    [URL5.lastPathComponent isEqual: @"foo/bar"])
	TEST(@"-[query]",
	    [URL1.query isEqual: @"que#ry=1&f&oo=b=ar"] && URL4.query == nil)
	TEST(@"-[queryDictionary]",
	    [URL1.queryDictionary isEqual:
	    [OFDictionary dictionaryWithKeysAndObjects:
	    @"que#ry", @"1", @"f&oo", @"b=ar", nil]]);
	TEST(@"-[fragment]",
	    [URL1.fragment isEqual: @"frag#ment"] && URL4.fragment == nil)

	TEST(@"-[copy]", R(URL4 = [[URL1 copy] autorelease]))

	TEST(@"-[isEqual:]", [URL1 isEqual: URL4] && ![URL2 isEqual: URL3] &&
	    [[OFURL URLWithString: @"HTTP://bar/"] isEqual: URL3])

	TEST(@"-[hash:]", URL1.hash == URL4.hash && URL2.hash != URL3.hash)

	EXPECT_EXCEPTION(@"Detection of invalid format",
	    OFInvalidFormatException, [OFURL URLWithString: @"http"])

	mutableURL = [OFMutableURL URL];

	TEST(@"-[setScheme:]",
	    (mutableURL.scheme = @"ht:tp") &&
	    [mutableURL.URLEncodedScheme isEqual: @"ht%3Atp"])

	TEST(@"-[setURLEncodedScheme:]",
	    (mutableURL.URLEncodedScheme = @"ht%3Atp") &&
	    [mutableURL.scheme isEqual: @"ht:tp"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedScheme:] with invalid characters fails",
	    OFInvalidFormatException, mutableURL.URLEncodedScheme = @"~")

	TEST(@"-[setHost:]",
	    (mutableURL.host = @"ho:st") &&
	    [mutableURL.URLEncodedHost isEqual: @"ho%3Ast"] &&
	    (mutableURL.host = @"12:34:ab") &&
	    [mutableURL.URLEncodedHost isEqual: @"[12:34:ab]"] &&
	    (mutableURL.host = @"12:34:aB") &&
	    [mutableURL.URLEncodedHost isEqual: @"[12:34:aB]"] &&
	    (mutableURL.host = @"12:34:g") &&
	    [mutableURL.URLEncodedHost isEqual: @"12%3A34%3Ag"])

	TEST(@"-[setURLEncodedHost:]",
	    (mutableURL.URLEncodedHost = @"ho%3Ast") &&
	    [mutableURL.host isEqual: @"ho:st"] &&
	    (mutableURL.URLEncodedHost = @"[12:34]") &&
	    [mutableURL.host isEqual: @"12:34"] &&
	    (mutableURL.URLEncodedHost = @"[12::ab]") &&
	    [mutableURL.host isEqual: @"12::ab"])

	EXPECT_EXCEPTION(@"-[setURLEncodedHost:] with invalid characters fails"
	    " #1", OFInvalidFormatException, mutableURL.URLEncodedHost = @"/")

	EXPECT_EXCEPTION(@"-[setURLEncodedHost:] with invalid characters fails"
	    " #2", OFInvalidFormatException,
	    mutableURL.URLEncodedHost = @"[12:34")

	EXPECT_EXCEPTION(@"-[setURLEncodedHost:] with invalid characters fails"
	    " #3", OFInvalidFormatException,
	    mutableURL.URLEncodedHost = @"[a::g]")

	TEST(@"-[setUser:]",
	    (mutableURL.user = @"us:er") &&
	    [mutableURL.URLEncodedUser isEqual: @"us%3Aer"])

	TEST(@"-[setURLEncodedUser:]",
	    (mutableURL.URLEncodedUser = @"us%3Aer") &&
	    [mutableURL.user isEqual: @"us:er"])

	EXPECT_EXCEPTION(@"-[setURLEncodedUser:] with invalid characters fails",
	    OFInvalidFormatException, mutableURL.URLEncodedHost = @"/")

	TEST(@"-[setPassword:]",
	    (mutableURL.password = @"pass:word") &&
	    [mutableURL.URLEncodedPassword isEqual: @"pass%3Aword"])

	TEST(@"-[setURLEncodedPassword:]",
	    (mutableURL.URLEncodedPassword = @"pass%3Aword") &&
	    [mutableURL.password isEqual: @"pass:word"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedPassword:] with invalid characters fails",
	    OFInvalidFormatException, mutableURL.URLEncodedPassword = @"/")

	TEST(@"-[setPath:]",
	    (mutableURL.path = @"pa/th@?") &&
	    [mutableURL.URLEncodedPath isEqual: @"pa/th@%3F"])

	TEST(@"-[setURLEncodedPath:]",
	    (mutableURL.URLEncodedPath = @"pa/th@%3F") &&
	    [mutableURL.path isEqual: @"pa/th@?"])

	EXPECT_EXCEPTION(@"-[setURLEncodedPath:] with invalid characters fails",
	    OFInvalidFormatException, mutableURL.URLEncodedPath = @"?")

	TEST(@"-[setQuery:]",
	    (mutableURL.query = @"que/ry?#") &&
	    [mutableURL.URLEncodedQuery isEqual: @"que/ry?%23"])

	TEST(@"-[setURLEncodedQuery:]",
	    (mutableURL.URLEncodedQuery = @"que/ry?%23") &&
	    [mutableURL.query isEqual: @"que/ry?#"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedQuery:] with invalid characters fails",
	    OFInvalidFormatException, mutableURL.URLEncodedQuery = @"`")

	TEST(@"-[setQueryDictionary:]",
	    (mutableURL.queryDictionary =
	    [OFDictionary dictionaryWithKeysAndObjects:
	    @"foo&bar", @"baz=qux", @"f=oobar", @"b&azqux", nil]) &&
	    [mutableURL.URLEncodedQuery isEqual:
	    @"foo%26bar=baz%3Dqux&f%3Doobar=b%26azqux"])

	TEST(@"-[setFragment:]",
	    (mutableURL.fragment = @"frag/ment?#") &&
	    [mutableURL.URLEncodedFragment isEqual: @"frag/ment?%23"])

	TEST(@"-[setURLEncodedFragment:]",
	    (mutableURL.URLEncodedFragment = @"frag/ment?%23") &&
	    [mutableURL.fragment isEqual: @"frag/ment?#"])

	EXPECT_EXCEPTION(
	    @"-[setURLEncodedFragment:] with invalid characters fails",
	    OFInvalidFormatException, mutableURL.URLEncodedFragment = @"`")

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
