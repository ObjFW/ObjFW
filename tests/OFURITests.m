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

static OFString *const module = @"OFURI";
static OFString *URIString = @"ht+tp://us%3Aer:p%40w@ho%3Ast:1234/"
    @"pa%3Fth?que%23ry=1&f%26oo=b%3dar#frag%23ment";

@implementation TestsAppDelegate (OFURITests)
- (void)URITests
{
	void *pool = objc_autoreleasePoolPush();
	OFURI *URI1, *URI2, *URI3, *URI4, *URI5, *URI6, *URI7, *URI8, *URI9;
	OFURI *URI10, *URI11;
	OFMutableURI *mutableURI;

	TEST(@"+[URIWithString:]",
	    R(URI1 = [OFURI URIWithString: URIString]) &&
	    R(URI2 = [OFURI URIWithString: @"http://foo:80"]) &&
	    R(URI3 = [OFURI URIWithString: @"http://bar/"]) &&
	    R(URI4 = [OFURI URIWithString: @"file:///etc/passwd"]) &&
	    R(URI5 = [OFURI URIWithString: @"http://foo/bar/qux/foo%2fbar"]) &&
	    R(URI6 = [OFURI URIWithString: @"https://[12:34::56:abcd]/"]) &&
	    R(URI7 = [OFURI URIWithString: @"https://[12:34::56:abcd]:234/"]) &&
	    R(URI8 = [OFURI URIWithString: @"urn:qux:foo"]) &&
	    R(URI9 = [OFURI URIWithString: @"file:/foo?query#frag"]) &&
	    R(URI10 = [OFURI URIWithString: @"file:foo@bar/qux?query#frag"]) &&
	    R(URI11 = [OFURI URIWithString: @"http://ä/ö?ü"]))

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"ht,tp://foo"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"http://f`oo"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"http://foo/`"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"http://foo/foo?`"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #5",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"http://foo/foo?foo#`"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #6",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"https://[g]/"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #7",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"https://[f]:/"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #8",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"https://[f]:f/"])

	EXPECT_EXCEPTION(@"+[URIWithString:] fails with invalid characters #9",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"foo:"])

	TEST(@"+[URIWithString:relativeToURI:]",
	    [[[OFURI URIWithString: @"/foo" relativeToURI: URI1] string]
	    isEqual: @"ht+tp://us%3Aer:p%40w@ho%3Ast:1234/foo"] &&
	    [[[OFURI URIWithString: @"foo/bar?q"
		     relativeToURI: [OFURI URIWithString: @"http://h/qux/quux"]]
	    string] isEqual: @"http://h/qux/foo/bar?q"] &&
	    [[[OFURI URIWithString: @"foo/bar"
		     relativeToURI: [OFURI URIWithString: @"http://h/qux/?x"]]
	    string] isEqual: @"http://h/qux/foo/bar"] &&
	    [[[OFURI URIWithString: @"http://foo/?q"
		     relativeToURI: URI1] string] isEqual: @"http://foo/?q"] &&
	    [[[OFURI URIWithString: @"foo"
		     relativeToURI: [OFURI URIWithString: @"http://foo/bar"]]
	    string] isEqual: @"http://foo/foo"] &&
	    [[[OFURI URIWithString: @"foo"
		     relativeToURI: [OFURI URIWithString: @"http://foo"]]
	    string] isEqual: @"http://foo/foo"])

	EXPECT_EXCEPTION(
	    @"+[URIWithString:relativeToURI:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"`" relativeToURI: URI1])

	EXPECT_EXCEPTION(
	    @"+[URIWithString:relativeToURI:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"/`" relativeToURI: URI1])

	EXPECT_EXCEPTION(
	    @"+[URIWithString:relativeToURI:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"?`" relativeToURI: URI1])

	EXPECT_EXCEPTION(
	    @"+[URIWithString:relativeToURI:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFURI URIWithString: @"#`" relativeToURI: URI1])

#ifdef OF_HAVE_FILES
	TEST(@"+[fileURIWithPath:]",
	    [[[OFURI fileURIWithPath: @"testfile.txt"] fileSystemRepresentation]
	    isEqual: [[OFFileManager defaultManager].currentDirectoryPath
	    stringByAppendingPathComponent: @"testfile.txt"]])

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OFURI *tmp;
	TEST(@"+[fileURIWithPath:] for c:\\",
	    (tmp = [OFURI fileURIWithPath: @"c:\\"]) &&
	    [tmp.string isEqual: @"file:/c:/"] &&
	    [tmp.fileSystemRepresentation isEqual: @"c:\\"])
# endif

# ifdef OF_WINDOWS
	TEST(@"+[fileURIWithPath:] with UNC",
	    (tmp = [OFURI fileURIWithPath: @"\\\\foo\\bar"
			      isDirectory: false]) &&
	    [tmp.host isEqual: @"foo"] && [tmp.path isEqual: @"/bar"] &&
	    [tmp.string isEqual: @"file://foo/bar"] &&
	    [tmp.fileSystemRepresentation isEqual: @"\\\\foo\\bar"] &&
	    (tmp = [OFURI fileURIWithPath: @"\\\\test" isDirectory: true]) &&
	    [tmp.host isEqual: @"test"] && [tmp.path isEqual: @"/"] &&
	    [tmp.string isEqual: @"file://test/"] &&
	    [tmp.fileSystemRepresentation isEqual: @"\\\\test"])
# endif
#endif

	TEST(@"-[string]",
	    [URI1.string isEqual: URIString] &&
	    [URI2.string isEqual: @"http://foo:80"] &&
	    [URI3.string isEqual: @"http://bar/"] &&
	    [URI4.string isEqual: @"file:///etc/passwd"] &&
	    [URI5.string isEqual: @"http://foo/bar/qux/foo%2fbar"] &&
	    [URI6.string isEqual: @"https://[12:34::56:abcd]/"] &&
	    [URI7.string isEqual: @"https://[12:34::56:abcd]:234/"] &&
	    [URI8.string isEqual: @"urn:qux:foo"] &&
	    [URI9.string isEqual: @"file:/foo?query#frag"] &&
	    [URI10.string isEqual: @"file:foo@bar/qux?query#frag"] &&
	    [URI11.string isEqual: @"http://ä/ö?ü"])

	TEST(@"-[scheme]",
	    [URI1.scheme isEqual: @"ht+tp"] && [URI4.scheme isEqual: @"file"] &&
	    [URI9.scheme isEqual: @"file"] && [URI10.scheme isEqual: @"file"] &&
	    [URI11.scheme isEqual: @"http"])

	TEST(@"-[user]", [URI1.user isEqual: @"us:er"] && URI4.user == nil &&
	    URI10.user == nil && URI11.user == nil)
	TEST(@"-[password]",
	    [URI1.password isEqual: @"p@w"] && URI4.password == nil &&
	    URI10.password == nil && URI11.password == nil)
	TEST(@"-[host]", [URI1.host isEqual: @"ho:st"] &&
	    [URI6.host isEqual: @"12:34::56:abcd"] &&
	    [URI7.host isEqual: @"12:34::56:abcd"] &&
	    URI8.host == nil && URI9.host == nil && URI10.host == nil &&
	    [URI11.host isEqual: @"ä"])
	TEST(@"-[port]", URI1.port.unsignedShortValue == 1234 &&
	    [URI4 port] == nil && URI7.port.unsignedShortValue == 234 &&
	    URI8.port == nil && URI9.port == nil && URI10.port == nil &&
	    URI11.port == nil)
	TEST(@"-[path]",
	    [URI1.path isEqual: @"/pa?th"] &&
	    [URI4.path isEqual: @"/etc/passwd"] &&
	    [URI8.path isEqual: @"qux:foo"] &&
	    [URI9.path isEqual: @"/foo"] &&
	    [URI10.path isEqual: @"foo@bar/qux"] &&
	    [URI11.path isEqual: @"/ö"])
	TEST(@"-[pathComponents]",
	    [URI1.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"pa?th", nil]] &&
	    [URI4.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"etc", @"passwd", nil]] &&
	    [URI5.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"bar", @"qux", @"foo/bar", nil]])
	TEST(@"-[lastPathComponent]",
	    [[[OFURI URIWithString: @"http://host/foo//bar/baz"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFURI URIWithString: @"http://host/foo//bar/baz/"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFURI URIWithString: @"http://host/foo/"]
	    lastPathComponent] isEqual: @"foo"] &&
	    [[[OFURI URIWithString: @"http://host/"]
	    lastPathComponent] isEqual: @"/"] &&
	    [URI5.lastPathComponent isEqual: @"foo/bar"])
	TEST(@"-[query]",
	    [URI1.query isEqual: @"que#ry=1&f&oo=b=ar"] && URI4.query == nil &&
	    [URI9.query isEqual: @"query"] && [URI10.query isEqual: @"query"] &&
	    [URI11.query isEqual: @"ü"])
	TEST(@"-[queryItems]",
	    [URI1.queryItems isEqual: [OFArray arrayWithObjects:
	    [OFPair pairWithFirstObject: @"que#ry" secondObject: @"1"],
	    [OFPair pairWithFirstObject: @"f&oo" secondObject: @"b=ar"], nil]]);
	TEST(@"-[fragment]",
	    [URI1.fragment isEqual: @"frag#ment"] && URI4.fragment == nil &&
	    [URI9.fragment isEqual: @"frag"] &&
	    [URI10.fragment isEqual: @"frag"])

	TEST(@"-[copy]", R(URI4 = [[URI1 copy] autorelease]))

	TEST(@"-[isEqual:]", [URI1 isEqual: URI4] && ![URI2 isEqual: URI3] &&
	    [[OFURI URIWithString: @"HTTP://bar/"] isEqual: URI3])

	TEST(@"-[hash:]", URI1.hash == URI4.hash && URI2.hash != URI3.hash)

	EXPECT_EXCEPTION(@"Detection of invalid format",
	    OFInvalidFormatException, [OFURI URIWithString: @"http"])

	mutableURI = [OFMutableURI URIWithScheme: @"dummy"];

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedScheme:] with invalid characters fails",
	    OFInvalidFormatException, mutableURI.scheme = @"%20")

	TEST(@"-[setHost:]",
	    (mutableURI.host = @"ho:st") &&
	    [mutableURI.percentEncodedHost isEqual: @"ho%3Ast"] &&
	    (mutableURI.host = @"12:34:ab") &&
	    [mutableURI.percentEncodedHost isEqual: @"[12:34:ab]"] &&
	    (mutableURI.host = @"12:34:aB") &&
	    [mutableURI.percentEncodedHost isEqual: @"[12:34:aB]"] &&
	    (mutableURI.host = @"12:34:g") &&
	    [mutableURI.percentEncodedHost isEqual: @"12%3A34%3Ag"])

	TEST(@"-[setPercentEncodedHost:]",
	    (mutableURI.percentEncodedHost = @"ho%3Ast") &&
	    [mutableURI.host isEqual: @"ho:st"] &&
	    (mutableURI.percentEncodedHost = @"[12:34]") &&
	    [mutableURI.host isEqual: @"12:34"] &&
	    (mutableURI.percentEncodedHost = @"[12::ab]") &&
	    [mutableURI.host isEqual: @"12::ab"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedHost:] with invalid characters fails #1",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedHost = @"/")

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedHost:] with invalid characters fails #2",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedHost = @"[12:34")

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedHost:] with invalid characters fails #3",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedHost = @"[a::g]")

	TEST(@"-[setUser:]",
	    (mutableURI.user = @"us:er") &&
	    [mutableURI.percentEncodedUser isEqual: @"us%3Aer"])

	TEST(@"-[setPercentEncodedUser:]",
	    (mutableURI.percentEncodedUser = @"us%3Aer") &&
	    [mutableURI.user isEqual: @"us:er"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedUser:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedHost = @"/")

	TEST(@"-[setPassword:]",
	    (mutableURI.password = @"pass:word") &&
	    [mutableURI.percentEncodedPassword isEqual: @"pass%3Aword"])

	TEST(@"-[setPercentEncodedPassword:]",
	    (mutableURI.percentEncodedPassword = @"pass%3Aword") &&
	    [mutableURI.password isEqual: @"pass:word"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedPassword:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedPassword = @"/")

	TEST(@"-[setPath:]",
	    (mutableURI.path = @"pa/th@?") &&
	    [mutableURI.percentEncodedPath isEqual: @"pa/th@%3F"])

	TEST(@"-[setPercentEncodedPath:]",
	    (mutableURI.percentEncodedPath = @"pa/th@%3F") &&
	    [mutableURI.path isEqual: @"pa/th@?"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedPath:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedPath = @"?")

	TEST(@"-[setQuery:]",
	    (mutableURI.query = @"que/ry?#") &&
	    [mutableURI.percentEncodedQuery isEqual: @"que/ry?%23"])

	TEST(@"-[setPercentEncodedQuery:]",
	    (mutableURI.percentEncodedQuery = @"que/ry?%23") &&
	    [mutableURI.query isEqual: @"que/ry?#"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedQuery:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedQuery = @"`")

	TEST(@"-[setQueryItems:]",
	    (mutableURI.queryItems = [OFArray arrayWithObjects:
	    [OFPair pairWithFirstObject: @"foo&bar" secondObject: @"baz=qux"],
	    [OFPair pairWithFirstObject: @"f=oobar" secondObject: @"b&azqux"],
	    nil]) && [mutableURI.percentEncodedQuery isEqual:
	    @"foo%26bar=baz%3Dqux&f%3Doobar=b%26azqux"])

	TEST(@"-[setFragment:]",
	    (mutableURI.fragment = @"frag/ment?#") &&
	    [mutableURI.percentEncodedFragment isEqual: @"frag/ment?%23"])

	TEST(@"-[setPercentEncodedFragment:]",
	    (mutableURI.percentEncodedFragment = @"frag/ment?%23") &&
	    [mutableURI.fragment isEqual: @"frag/ment?#"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedFragment:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableURI.percentEncodedFragment = @"`")

	TEST(@"-[URIByAppendingPathComponent:isDirectory:]",
	    [[[OFURI URIWithString: @"file:///foo/bar"]
	    URIByAppendingPathComponent: @"qux" isDirectory: false] isEqual:
	    [OFURI URIWithString: @"file:///foo/bar/qux"]] &&
	    [[[OFURI URIWithString: @"file:///foo/bar/"]
	    URIByAppendingPathComponent: @"qux" isDirectory: false] isEqual:
	    [OFURI URIWithString: @"file:///foo/bar/qux"]] &&
	    [[[OFURI URIWithString: @"file:///foo/bar/"]
	    URIByAppendingPathComponent: @"qu?x" isDirectory: false] isEqual:
	    [OFURI URIWithString: @"file:///foo/bar/qu%3Fx"]] &&
	    [[[OFURI URIWithString: @"file:///foo/bar/"]
	    URIByAppendingPathComponent: @"qu?x" isDirectory: true] isEqual:
	    [OFURI URIWithString: @"file:///foo/bar/qu%3Fx/"]])

	TEST(@"-[URIByStandardizingPath]",
	    [[[OFURI URIWithString: @"http://foo/bar/.."]
	    URIByStandardizingPath] isEqual:
	    [OFURI URIWithString: @"http://foo/"]] &&
	    [[[OFURI URIWithString: @"http://foo/bar/%2E%2E/../qux/"]
	    URIByStandardizingPath] isEqual:
	    [OFURI URIWithString: @"http://foo/bar/qux/"]] &&
	    [[[OFURI URIWithString: @"http://foo/bar/./././qux/./"]
	    URIByStandardizingPath] isEqual:
	    [OFURI URIWithString: @"http://foo/bar/qux/"]] &&
	    [[[OFURI URIWithString: @"http://foo/bar/../../qux"]
	    URIByStandardizingPath] isEqual:
	    [OFURI URIWithString: @"http://foo/../qux"]])

	objc_autoreleasePoolPop(pool);
}
@end
