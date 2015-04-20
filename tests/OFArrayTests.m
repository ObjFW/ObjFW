/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#import "OFArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFOutOfRangeException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFArray";
static OFString *c_ary[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@implementation TestsAppDelegate (OFArrayTests)
- (void)arrayTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *a[3];
	OFMutableArray *m[2];
	OFEnumerator *enumerator;
	id obj;
	bool ok;
	size_t i;

	TEST(@"+[array]", (m[0] = [OFMutableArray array]))

	TEST(@"+[arrayWithObjects:]",
	    (a[0] = [OFArray arrayWithObjects: @"Foo", @"Bar", @"Baz", nil]))

	TEST(@"+[arrayWithObjects:count:]",
	    (a[1] = [OFArray arrayWithObjects: c_ary
					count: 3]) &&
	    [a[1] isEqual: a[0]])

	TEST(@"-[description]",
	    [[a[0] description ]isEqual: @"(\n\tFoo,\n\tBar,\n\tBaz\n)"])

	TEST(@"-[addObject:]", R([m[0] addObject: c_ary[0]]) &&
	    R([m[0] addObject: c_ary[2]]))

	TEST(@"-[insertObject:atIndex:]", R([m[0] insertObject: c_ary[1]
						       atIndex: 1]))

	TEST(@"-[count]", [m[0] count] == 3 && [a[0] count] == 3 &&
	    [a[1] count] == 3)

	TEST(@"-[isEqual:]", [m[0] isEqual: a[0]] && [a[0] isEqual: a[1]])

	TEST(@"-[objectAtIndex:]",
	    [[m[0] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[m[0] objectAtIndex: 2] isEqual: c_ary[2]] &&
	    [[a[0] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[a[0] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[a[0] objectAtIndex: 2] isEqual: c_ary[2]] &&
	    [[a[1] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[a[1] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[a[1] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[containsObject:]",
	    [a[0] containsObject: c_ary[1]] &&
	    ![a[0] containsObject: @"nonexistant"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [a[0] containsObjectIdenticalTo: c_ary[1]] &&
	    ![a[0] containsObjectIdenticalTo:
	    [OFString stringWithString: c_ary[1]]])

	TEST(@"-[indexOfObject:]", [a[0] indexOfObject: c_ary[1]] == 1)

	TEST(@"-[indexOfObjectIdenticalTo:]",
	    [a[1] indexOfObjectIdenticalTo: c_ary[1]] == 1)

	TEST(@"-[objectsInRange:]",
	    [[a[0] objectsInRange: of_range(1, 2)] isEqual:
	    ([OFArray arrayWithObjects: c_ary[1], c_ary[2], nil])])

	TEST(@"-[replaceObject:withObject:]",
	    R([m[0] replaceObject: c_ary[1]
		       withObject: c_ary[0]]) &&
	    [[m[0] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 1] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[replaceObject:identicalTo:]",
	    R([m[0] replaceObjectIdenticalTo: c_ary[0]
				  withObject: c_ary[1]]) &&
	    [[m[0] objectAtIndex: 0] isEqual: c_ary[1]] &&
	    [[m[0] objectAtIndex: 1] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[replaceObjectAtIndex:withObject:]",
	    R([m[0] replaceObjectAtIndex: 0
			      withObject: c_ary[0]]) &&
	    [[m[0] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 1] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[removeObject:]",
	    R([m[0] removeObject: c_ary[0]]) && [m[0] count] == 2)

	TEST(@"-[removeObjectIdenticalTo:]",
	    R([m[0] removeObjectIdenticalTo: c_ary[2]]) && [m[0] count] == 1)

	m[1] = [[a[0] mutableCopy] autorelease];
	TEST(@"-[removeObjectAtIndex:]", R([m[1] removeObjectAtIndex: 1]) &&
	    [m[1] count] == 2 && [[m[1] objectAtIndex: 1] isEqual: c_ary[2]])

	m[1] = [[a[0] mutableCopy] autorelease];
	TEST(@"-[removeObjectsInRange:]",
	    R([m[1] removeObjectsInRange: of_range(0, 2)]) &&
	    [m[1] count] == 1 && [[m[1] objectAtIndex: 0] isEqual: c_ary[2]])

	m[1] = [[a[0] mutableCopy] autorelease];
	[m[1] addObject: @"qux"];
	[m[1] addObject: @"last"];
	TEST(@"-[reverse]",
	    R([m[1] reverse]) && [m[1] isEqual: ([OFArray arrayWithObjects:
	    @"last", @"qux", @"Baz", @"Bar", @"Foo", nil])])

	m[1] = [[a[0] mutableCopy] autorelease];
	[m[1] addObject: @"qux"];
	[m[1] addObject: @"last"];
	TEST(@"-[reversedArray]",
	    [[m[1] reversedArray] isEqual: ([OFArray arrayWithObjects:
	    @"last", @"qux", @"Baz", @"Bar", @"Foo", nil])])

	m[1] = [[a[0] mutableCopy] autorelease];
	[m[1] addObject: @"0"];
	[m[1] addObject: @"z"];
	TEST(@"-[sortedArray]",
	    [[m[1] sortedArray] isEqual: ([OFArray arrayWithObjects:
	    @"0", @"Bar", @"Baz", @"Foo", @"z", nil])] &&
	    [[m[1] sortedArrayWithOptions: OF_ARRAY_SORT_DESCENDING]
	    isEqual: ([OFArray arrayWithObjects:
	    @"z", @"Foo", @"Baz", @"Bar", @"0", nil])])

	EXPECT_EXCEPTION(@"Detect out of range in -[objectAtIndex:]",
	    OFOutOfRangeException, [a[0] objectAtIndex: [a[0] count]])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeObjectsInRange:]",
	    OFOutOfRangeException, [m[0] removeObjectsInRange:
		of_range(0, [m[0] count] + 1)])

	TEST(@"-[componentsJoinedByString:]",
	    (a[1] = [OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]) &&
	    [[a[1] componentsJoinedByString: @" "] isEqual: @"foo bar baz"] &&
	    (a[1] = [OFArray arrayWithObject: @"foo"]) &&
	    [[a[1] componentsJoinedByString: @" "] isEqual: @"foo"])

	TEST(@"-[componentsJoinedByString:options]",
	    (a[1] = [OFArray arrayWithObjects: @"", @"foo", @"", @"", @"bar",
	    @"", nil]) && [[a[1] componentsJoinedByString: @" "
						  options: OF_ARRAY_SKIP_EMPTY]
	    isEqual: @"foo bar"])

	m[0] = [[a[0] mutableCopy] autorelease];
	ok = true;
	i = 0;

	TEST(@"-[objectEnumerator]", (enumerator = [m[0] objectEnumerator]))

	while ((obj = [enumerator nextObject]) != nil) {
		if (![obj isEqual: c_ary[i]])
			ok = false;
		[m[0] replaceObjectAtIndex: i
				withObject: @""];
		i++;
	}

	if ([m[0] count] != i)
		ok = false;

	TEST(@"OFEnumerator's -[nextObject]", ok)

	[enumerator reset];
	[m[0] removeObjectAtIndex: 0];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [enumerator nextObject])

#ifdef OF_HAVE_FAST_ENUMERATION
	m[0] = [[a[0] mutableCopy] autorelease];
	ok = true;
	i = 0;

	for (OFString *s in m[0]) {
		if (![s isEqual: c_ary[i]])
			ok = false;
		[m[0] replaceObjectAtIndex: i
				withObject: @""];
		i++;
	}

	if ([m[0] count] != i)
		ok = false;

	TEST(@"Fast Enumeration", ok)

	[m[0] replaceObjectAtIndex: 0
			withObject: c_ary[0]];
	[m[0] replaceObjectAtIndex: 1
			withObject: c_ary[1]];
	[m[0] replaceObjectAtIndex: 2
			withObject: c_ary[2]];

	ok = false;
	i = 0;
	@try {
		for (OFString *s in m[0]) {
			(void)s;

			if (i == 0)
				[m[0] addObject: @""];

			i++;
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[m[0] removeLastObject];
#endif

#ifdef OF_HAVE_BLOCKS
	{
		__block bool ok = true;
		__block size_t count = 0;
		OFArray *cmp = a[0];
		OFMutableArray *a2;

		m[0] = [[a[0] mutableCopy] autorelease];
		[m[0] enumerateObjectsUsingBlock:
		    ^ (id obj, size_t idx, bool *stop) {
			    count++;
			    if (![obj isEqual: [cmp objectAtIndex: idx]])
				    ok = false;
		}];

		if (count != [cmp count])
			ok = false;

		TEST(@"Enumeration using blocks", ok)

		ok = false;
		a2 = m[0];
		@try {
			[a2 enumerateObjectsUsingBlock:
			    ^ (id obj, size_t idx, bool *stop) {
				[a2 removeObjectAtIndex: idx];
			}];
		} @catch (OFEnumerationMutationException *e) {
			ok = true;
		} @catch (OFOutOfRangeException *e) {
			/*
			 * Out of bounds access due to enumeration not being
			 * detected.
			 */
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    ok)
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([m[0] replaceObjectsUsingBlock: ^ id (id obj, size_t idx) {
		switch (idx) {
		case 0:
			return @"foo";
		case 1:
			return @"bar";
		}

		return nil;
		}]) && [[m[0] description] isEqual: @"(\n\tfoo,\n\tbar\n)"])

	TEST(@"-[mappedArrayUsingBLock]",
	    [[[m[0] mappedArrayUsingBlock: ^ id (id obj, size_t idx) {
		switch (idx) {
		case 0:
			return @"foobar";
		case 1:
			return @"qux";
		}

		return nil;
	    }] description] isEqual: @"(\n\tfoobar,\n\tqux\n)"])

	TEST(@"-[filteredArrayUsingBlock:]",
	   [[[m[0] filteredArrayUsingBlock: ^ bool (id obj, size_t idx) {
		return [obj isEqual: @"foo"];
	    }] description] isEqual: @"(\n\tfoo\n)"])

	TEST(@"-[foldUsingBlock:]",
	    [([OFArray arrayWithObjects: [OFMutableString string], @"foo",
	    @"bar", @"baz", nil]) foldUsingBlock: ^ id (id left, id right) {
		[left appendString: right];
		return left;
	    }])
#endif

	[pool drain];
}
@end
