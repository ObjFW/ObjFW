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

static OFString *const module = @"OFIRI";
static OFString *IRIString = @"ht+tp://us%3Aer:p%40w@ho%3Ast:1234/"
    @"pa%3Fth?que%23ry=1&f%26oo=b%3dar#frag%23ment";

@implementation TestsAppDelegate (OFIRITests)
- (void)IRITests
{
	void *pool = objc_autoreleasePoolPush();
	OFIRI *IRI1, *IRI2, *IRI3, *IRI4, *IRI5, *IRI6, *IRI7, *IRI8, *IRI9;
	OFIRI *IRI10, *IRI11;
	OFMutableIRI *mutableIRI;

	TEST(@"+[IRIWithString:]",
	    R(IRI1 = [OFIRI IRIWithString: IRIString]) &&
	    R(IRI2 = [OFIRI IRIWithString: @"http://foo:80"]) &&
	    R(IRI3 = [OFIRI IRIWithString: @"http://bar/"]) &&
	    R(IRI4 = [OFIRI IRIWithString: @"file:///etc/passwd"]) &&
	    R(IRI5 = [OFIRI IRIWithString: @"http://foo/bar/qux/foo%2fbar"]) &&
	    R(IRI6 = [OFIRI IRIWithString: @"https://[12:34::56:abcd]/"]) &&
	    R(IRI7 = [OFIRI IRIWithString: @"https://[12:34::56:abcd]:234/"]) &&
	    R(IRI8 = [OFIRI IRIWithString: @"urn:qux:foo"]) &&
	    R(IRI9 = [OFIRI IRIWithString: @"file:/foo?query#frag"]) &&
	    R(IRI10 = [OFIRI IRIWithString: @"file:foo@bar/qux?query#frag"]) &&
	    R(IRI11 = [OFIRI IRIWithString: @"http://ä/ö?ü"]))

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"ht,tp://foo"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"http://f`oo"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"http://foo/`"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"http://foo/foo?`"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #5",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"http://foo/foo?foo#`"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #6",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"https://[g]/"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #7",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"https://[f]:/"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #8",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"https://[f]:f/"])

	EXPECT_EXCEPTION(@"+[IRIWithString:] fails with invalid characters #9",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"foo:"])

	TEST(@"+[IRIWithString:relativeToIRI:]",
	    [[[OFIRI IRIWithString: @"/foo" relativeToIRI: IRI1] string]
	    isEqual: @"ht+tp://us%3Aer:p%40w@ho%3Ast:1234/foo"] &&
	    [[[OFIRI IRIWithString: @"foo/bar?q"
		     relativeToIRI: [OFIRI IRIWithString: @"http://h/qux/quux"]]
	    string] isEqual: @"http://h/qux/foo/bar?q"] &&
	    [[[OFIRI IRIWithString: @"foo/bar"
		     relativeToIRI: [OFIRI IRIWithString: @"http://h/qux/?x"]]
	    string] isEqual: @"http://h/qux/foo/bar"] &&
	    [[[OFIRI IRIWithString: @"http://foo/?q"
		     relativeToIRI: IRI1] string] isEqual: @"http://foo/?q"] &&
	    [[[OFIRI IRIWithString: @"foo"
		     relativeToIRI: [OFIRI IRIWithString: @"http://foo/bar"]]
	    string] isEqual: @"http://foo/foo"] &&
	    [[[OFIRI IRIWithString: @"foo"
		     relativeToIRI: [OFIRI IRIWithString: @"http://foo"]]
	    string] isEqual: @"http://foo/foo"])

	EXPECT_EXCEPTION(
	    @"+[IRIWithString:relativeToIRI:] fails with invalid characters #1",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"`" relativeToIRI: IRI1])

	EXPECT_EXCEPTION(
	    @"+[IRIWithString:relativeToIRI:] fails with invalid characters #2",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"/`" relativeToIRI: IRI1])

	EXPECT_EXCEPTION(
	    @"+[IRIWithString:relativeToIRI:] fails with invalid characters #3",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"?`" relativeToIRI: IRI1])

	EXPECT_EXCEPTION(
	    @"+[IRIWithString:relativeToIRI:] fails with invalid characters #4",
	    OFInvalidFormatException,
	    [OFIRI IRIWithString: @"#`" relativeToIRI: IRI1])

#ifdef OF_HAVE_FILES
	TEST(@"+[fileIRIWithPath:]",
	    [[[OFIRI fileIRIWithPath: @"testfile.txt"] fileSystemRepresentation]
	    isEqual: [[OFFileManager defaultManager].currentDirectoryPath
	    stringByAppendingPathComponent: @"testfile.txt"]])

# if defined(OF_WINDOWS) || defined(OF_MSDOS)
	OFIRI *tmp;
	TEST(@"+[fileIRIWithPath:] for c:\\",
	    (tmp = [OFIRI fileIRIWithPath: @"c:\\"]) &&
	    [tmp.string isEqual: @"file:/c:/"] &&
	    [tmp.fileSystemRepresentation isEqual: @"c:\\"])
# endif

# ifdef OF_WINDOWS
	TEST(@"+[fileIRIWithPath:] with UNC",
	    (tmp = [OFIRI fileIRIWithPath: @"\\\\foo\\bar"
			      isDirectory: false]) &&
	    [tmp.host isEqual: @"foo"] && [tmp.path isEqual: @"/bar"] &&
	    [tmp.string isEqual: @"file://foo/bar"] &&
	    [tmp.fileSystemRepresentation isEqual: @"\\\\foo\\bar"] &&
	    (tmp = [OFIRI fileIRIWithPath: @"\\\\test" isDirectory: true]) &&
	    [tmp.host isEqual: @"test"] && [tmp.path isEqual: @"/"] &&
	    [tmp.string isEqual: @"file://test/"] &&
	    [tmp.fileSystemRepresentation isEqual: @"\\\\test"])
# endif
#endif

	TEST(@"-[string]",
	    [IRI1.string isEqual: IRIString] &&
	    [IRI2.string isEqual: @"http://foo:80"] &&
	    [IRI3.string isEqual: @"http://bar/"] &&
	    [IRI4.string isEqual: @"file:///etc/passwd"] &&
	    [IRI5.string isEqual: @"http://foo/bar/qux/foo%2fbar"] &&
	    [IRI6.string isEqual: @"https://[12:34::56:abcd]/"] &&
	    [IRI7.string isEqual: @"https://[12:34::56:abcd]:234/"] &&
	    [IRI8.string isEqual: @"urn:qux:foo"] &&
	    [IRI9.string isEqual: @"file:/foo?query#frag"] &&
	    [IRI10.string isEqual: @"file:foo@bar/qux?query#frag"] &&
	    [IRI11.string isEqual: @"http://ä/ö?ü"])

	TEST(@"-[scheme]",
	    [IRI1.scheme isEqual: @"ht+tp"] && [IRI4.scheme isEqual: @"file"] &&
	    [IRI9.scheme isEqual: @"file"] && [IRI10.scheme isEqual: @"file"] &&
	    [IRI11.scheme isEqual: @"http"])

	TEST(@"-[user]", [IRI1.user isEqual: @"us:er"] && IRI4.user == nil &&
	    IRI10.user == nil && IRI11.user == nil)
	TEST(@"-[password]",
	    [IRI1.password isEqual: @"p@w"] && IRI4.password == nil &&
	    IRI10.password == nil && IRI11.password == nil)
	TEST(@"-[host]", [IRI1.host isEqual: @"ho:st"] &&
	    [IRI6.host isEqual: @"12:34::56:abcd"] &&
	    [IRI7.host isEqual: @"12:34::56:abcd"] &&
	    IRI8.host == nil && IRI9.host == nil && IRI10.host == nil &&
	    [IRI11.host isEqual: @"ä"])
	TEST(@"-[port]", IRI1.port.unsignedShortValue == 1234 &&
	    [IRI4 port] == nil && IRI7.port.unsignedShortValue == 234 &&
	    IRI8.port == nil && IRI9.port == nil && IRI10.port == nil &&
	    IRI11.port == nil)
	TEST(@"-[path]",
	    [IRI1.path isEqual: @"/pa?th"] &&
	    [IRI4.path isEqual: @"/etc/passwd"] &&
	    [IRI8.path isEqual: @"qux:foo"] &&
	    [IRI9.path isEqual: @"/foo"] &&
	    [IRI10.path isEqual: @"foo@bar/qux"] &&
	    [IRI11.path isEqual: @"/ö"])
	TEST(@"-[pathComponents]",
	    [IRI1.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"pa?th", nil]] &&
	    [IRI4.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"etc", @"passwd", nil]] &&
	    [IRI5.pathComponents isEqual:
	    [OFArray arrayWithObjects: @"/", @"bar", @"qux", @"foo/bar", nil]])
	TEST(@"-[lastPathComponent]",
	    [[[OFIRI IRIWithString: @"http://host/foo//bar/baz"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFIRI IRIWithString: @"http://host/foo//bar/baz/"]
	    lastPathComponent] isEqual: @"baz"] &&
	    [[[OFIRI IRIWithString: @"http://host/foo/"]
	    lastPathComponent] isEqual: @"foo"] &&
	    [[[OFIRI IRIWithString: @"http://host/"]
	    lastPathComponent] isEqual: @"/"] &&
	    [IRI5.lastPathComponent isEqual: @"foo/bar"])
	TEST(@"-[query]",
	    [IRI1.query isEqual: @"que#ry=1&f&oo=b=ar"] && IRI4.query == nil &&
	    [IRI9.query isEqual: @"query"] && [IRI10.query isEqual: @"query"] &&
	    [IRI11.query isEqual: @"ü"])
	TEST(@"-[queryItems]",
	    [IRI1.queryItems isEqual: [OFArray arrayWithObjects:
	    [OFPair pairWithFirstObject: @"que#ry" secondObject: @"1"],
	    [OFPair pairWithFirstObject: @"f&oo" secondObject: @"b=ar"], nil]]);
	TEST(@"-[fragment]",
	    [IRI1.fragment isEqual: @"frag#ment"] && IRI4.fragment == nil &&
	    [IRI9.fragment isEqual: @"frag"] &&
	    [IRI10.fragment isEqual: @"frag"])

	TEST(@"-[copy]", R(IRI4 = [[IRI1 copy] autorelease]))

	TEST(@"-[isEqual:]", [IRI1 isEqual: IRI4] && ![IRI2 isEqual: IRI3] &&
	    [[OFIRI IRIWithString: @"HTTP://bar/"] isEqual: IRI3])

	TEST(@"-[hash:]", IRI1.hash == IRI4.hash && IRI2.hash != IRI3.hash)

	EXPECT_EXCEPTION(@"Detection of invalid format",
	    OFInvalidFormatException, [OFIRI IRIWithString: @"http"])

	TEST(@"-[IRIByAddingPercentEncodingForUnicodeCharacters]",
	    [IRI11.IRIByAddingPercentEncodingForUnicodeCharacters
	    isEqual: [OFIRI IRIWithString: @"http://%C3%A4/%C3%B6?%C3%BC"]])

	mutableIRI = [OFMutableIRI IRIWithScheme: @"dummy"];

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedScheme:] with invalid characters fails",
	    OFInvalidFormatException, mutableIRI.scheme = @"%20")

	TEST(@"-[setHost:]",
	    (mutableIRI.host = @"ho:st") &&
	    [mutableIRI.percentEncodedHost isEqual: @"ho%3Ast"] &&
	    (mutableIRI.host = @"12:34:ab") &&
	    [mutableIRI.percentEncodedHost isEqual: @"[12:34:ab]"] &&
	    (mutableIRI.host = @"12:34:aB") &&
	    [mutableIRI.percentEncodedHost isEqual: @"[12:34:aB]"] &&
	    (mutableIRI.host = @"12:34:g") &&
	    [mutableIRI.percentEncodedHost isEqual: @"12%3A34%3Ag"])

	TEST(@"-[setPercentEncodedHost:]",
	    (mutableIRI.percentEncodedHost = @"ho%3Ast") &&
	    [mutableIRI.host isEqual: @"ho:st"] &&
	    (mutableIRI.percentEncodedHost = @"[12:34]") &&
	    [mutableIRI.host isEqual: @"12:34"] &&
	    (mutableIRI.percentEncodedHost = @"[12::ab]") &&
	    [mutableIRI.host isEqual: @"12::ab"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedHost:] with invalid characters fails #1",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedHost = @"/")

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedHost:] with invalid characters fails #2",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedHost = @"[12:34")

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedHost:] with invalid characters fails #3",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedHost = @"[a::g]")

	TEST(@"-[setUser:]",
	    (mutableIRI.user = @"us:er") &&
	    [mutableIRI.percentEncodedUser isEqual: @"us%3Aer"])

	TEST(@"-[setPercentEncodedUser:]",
	    (mutableIRI.percentEncodedUser = @"us%3Aer") &&
	    [mutableIRI.user isEqual: @"us:er"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedUser:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedHost = @"/")

	TEST(@"-[setPassword:]",
	    (mutableIRI.password = @"pass:word") &&
	    [mutableIRI.percentEncodedPassword isEqual: @"pass%3Aword"])

	TEST(@"-[setPercentEncodedPassword:]",
	    (mutableIRI.percentEncodedPassword = @"pass%3Aword") &&
	    [mutableIRI.password isEqual: @"pass:word"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedPassword:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedPassword = @"/")

	TEST(@"-[setPath:]",
	    (mutableIRI.path = @"pa/th@?") &&
	    [mutableIRI.percentEncodedPath isEqual: @"pa/th@%3F"])

	TEST(@"-[setPercentEncodedPath:]",
	    (mutableIRI.percentEncodedPath = @"pa/th@%3F") &&
	    [mutableIRI.path isEqual: @"pa/th@?"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedPath:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedPath = @"?")

	TEST(@"-[setQuery:]",
	    (mutableIRI.query = @"que/ry?#") &&
	    [mutableIRI.percentEncodedQuery isEqual: @"que/ry?%23"])

	TEST(@"-[setPercentEncodedQuery:]",
	    (mutableIRI.percentEncodedQuery = @"que/ry?%23") &&
	    [mutableIRI.query isEqual: @"que/ry?#"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedQuery:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedQuery = @"`")

	TEST(@"-[setQueryItems:]",
	    (mutableIRI.queryItems = [OFArray arrayWithObjects:
	    [OFPair pairWithFirstObject: @"foo&bar" secondObject: @"baz=qux"],
	    [OFPair pairWithFirstObject: @"f=oobar" secondObject: @"b&azqux"],
	    nil]) && [mutableIRI.percentEncodedQuery isEqual:
	    @"foo%26bar=baz%3Dqux&f%3Doobar=b%26azqux"])

	TEST(@"-[setFragment:]",
	    (mutableIRI.fragment = @"frag/ment?#") &&
	    [mutableIRI.percentEncodedFragment isEqual: @"frag/ment?%23"])

	TEST(@"-[setPercentEncodedFragment:]",
	    (mutableIRI.percentEncodedFragment = @"frag/ment?%23") &&
	    [mutableIRI.fragment isEqual: @"frag/ment?#"])

	EXPECT_EXCEPTION(
	    @"-[setPercentEncodedFragment:] with invalid characters fails",
	    OFInvalidFormatException,
	    mutableIRI.percentEncodedFragment = @"`")

	TEST(@"-[IRIByAppendingPathComponent:isDirectory:]",
	    [[[OFIRI IRIWithString: @"file:///foo/bar"]
	    IRIByAppendingPathComponent: @"qux" isDirectory: false] isEqual:
	    [OFIRI IRIWithString: @"file:///foo/bar/qux"]] &&
	    [[[OFIRI IRIWithString: @"file:///foo/bar/"]
	    IRIByAppendingPathComponent: @"qux" isDirectory: false] isEqual:
	    [OFIRI IRIWithString: @"file:///foo/bar/qux"]] &&
	    [[[OFIRI IRIWithString: @"file:///foo/bar/"]
	    IRIByAppendingPathComponent: @"qu?x" isDirectory: false] isEqual:
	    [OFIRI IRIWithString: @"file:///foo/bar/qu%3Fx"]] &&
	    [[[OFIRI IRIWithString: @"file:///foo/bar/"]
	    IRIByAppendingPathComponent: @"qu?x" isDirectory: true] isEqual:
	    [OFIRI IRIWithString: @"file:///foo/bar/qu%3Fx/"]])

	TEST(@"-[IRIByStandardizingPath]",
	    [[[OFIRI IRIWithString: @"http://foo/bar/.."]
	    IRIByStandardizingPath] isEqual:
	    [OFIRI IRIWithString: @"http://foo/"]] &&
	    [[[OFIRI IRIWithString: @"http://foo/bar/%2E%2E/../qux/"]
	    IRIByStandardizingPath] isEqual:
	    [OFIRI IRIWithString: @"http://foo/bar/qux/"]] &&
	    [[[OFIRI IRIWithString: @"http://foo/bar/./././qux/./"]
	    IRIByStandardizingPath] isEqual:
	    [OFIRI IRIWithString: @"http://foo/bar/qux/"]] &&
	    [[[OFIRI IRIWithString: @"http://foo/bar/../../qux"]
	    IRIByStandardizingPath] isEqual:
	    [OFIRI IRIWithString: @"http://foo/../qux"]])

	objc_autoreleasePoolPop(pool);
}
@end
