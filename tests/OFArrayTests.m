/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFArray";
static OFString *c_ary[] = {
	@"Foo",
	@"Bar",
	@"Baz",
	nil
};

@implementation TestsAppDelegate (OFArrayTests)
- (void)arrayTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *a[3];
	OFMutableArray *m[2];
	OFEnumerator *enumerator;
	id obj;
	BOOL ok;
	size_t i;

	TEST(@"+[array]", (m[0] = [OFMutableArray array]))

	TEST(@"+[arrayWithObjects:]",
	    (a[0] = [OFArray arrayWithObjects: @"Foo", @"Bar", @"Baz", nil]))

	TEST(@"+[arrayWithCArray:]", (a[1] = [OFArray arrayWithCArray: c_ary]))

	TEST(@"+[arrayWithCArray:length:]",
	    (a[2] = [OFArray arrayWithCArray: c_ary
				      length: 3]) &&
	    [a[2] isEqual: a[1]])

	TEST(@"-[addObject:]", R([m[0] addObject: c_ary[0]]) &&
	    R([m[0] addObject: c_ary[2]]))

	TEST(@"-[addObject:atIndex:]", R([m[0] addObject: c_ary[1]
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

	TEST(@"-[indexOfObject:]", [a[0] indexOfObject: c_ary[1]] == 1)

	TEST(@"-[indexOfObjectIdenticalTo:]",
	    [a[1] indexOfObjectIdenticalTo: c_ary[1]] == 1)

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
	    [[m[0] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[m[0] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[replaceObjectAtIndex:withObject:]",
	    [m[0] replaceObjectAtIndex: 0
			    withObject: c_ary[0]] &&
	    [[m[0] objectAtIndex: 0] isEqual: c_ary[0]] &&
	    [[m[0] objectAtIndex: 1] isEqual: c_ary[1]] &&
	    [[m[0] objectAtIndex: 2] isEqual: c_ary[2]])

	TEST(@"-[removeObject:]",
	    R([m[0] removeObject: c_ary[1]]) && [m[0] count] == 2)

	TEST(@"-[removeObjectIdenticalTo:]",
	    R([m[0] removeObjectIdenticalTo: c_ary[2]]) && [m[0] count] == 1)

	[m[0] addObject: c_ary[0]];
	[m[0] addObject: c_ary[1]];
	TEST(@"-[removeNObjects:]", R([m[0] removeNObjects: 2]) &&
	    [m[0] count] == 1 && [[m[0] objectAtIndex: 0] isEqual: c_ary[0]])

	m[1] = [[a[0] mutableCopy] autorelease];
	TEST(@"-[removeObjectAtIndex:]", [m[1] removeObjectAtIndex: 1] &&
	    [m[1] count] == 2 && [[m[1] objectAtIndex: 1] isEqual: c_ary[2]])

	m[1] = [[a[0] mutableCopy] autorelease];
	TEST(@"-[removeNObjects:atIndex:]", R([m[1] removeNObjects: 2
							   atIndex: 0]) &&
	    [m[1] count] == 1 && [[m[1] objectAtIndex: 0] isEqual: c_ary[2]])

	EXPECT_EXCEPTION(@"Detect out of range in -[objectAtIndex:]",
	    OFOutOfRangeException, [a[0] objectAtIndex: [a[0] count]])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeNItems:]",
	    OFOutOfRangeException, [m[0] removeNObjects: [m[0] count] + 1])

	TEST(@"-[componentsJoinedByString:]",
	    (a[1] = [OFArray arrayWithObjects: @"foo", @"bar", @"baz", nil]) &&
	    [[a[1] componentsJoinedByString: @" "] isEqual: @"foo bar baz"] &&
	    (a[1] = [OFArray arrayWithObject: @"foo"]) &&
	    [[a[1] componentsJoinedByString: @" "] isEqual: @"foo"])

	m[0] = [[a[0] mutableCopy] autorelease];
	ok = YES;
	i = 0;

	TEST(@"-[enumerator]", (enumerator = [m[0] enumerator]))

	while ((obj = [enumerator nextObject]) != nil) {
		if (![obj isEqual: c_ary[i]])
			ok = NO;
		[m[0] replaceObjectAtIndex: i
				withObject: @""];
		i++;
	}

	TEST(@"OFEnumerator's -[nextObject]", ok)

	[enumerator reset];
	[m[0] removeObjectAtIndex: 0];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [enumerator nextObject])

#ifdef OF_HAVE_FAST_ENUMERATION
	m[0] = [[a[0] mutableCopy] autorelease];
	ok = YES;
	i = 0;

	for (OFString *s in m[0]) {
		if (![s isEqual: c_ary[i]])
			ok = NO;
		[m[0] replaceObjectAtIndex: i
				withObject: @""];
		i++;
	}

	TEST(@"Fast Enumeration", ok)

	[m[0] replaceObjectAtIndex: 0
			withObject: c_ary[0]];
	[m[0] replaceObjectAtIndex: 1
			withObject: c_ary[1]];
	[m[0] replaceObjectAtIndex: 2
			withObject: c_ary[2]];

	ok = NO;
	@try {
		for (OFString *s in m[0])
			[m[0] addObject: @""];
	} @catch (OFEnumerationMutationException *e) {
		ok = YES;
		[e dealloc];
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[m[0] removeNObjects: 1];
#endif

#ifdef OF_HAVE_BLOCKS
	{
		__block BOOL ok = YES;
		__block size_t count = 0;
		OFArray *cmp = a[0];
		OFMutableArray *a2;

		m[0] = [[a[0] mutableCopy] autorelease];
		[m[0] enumerateObjectsUsingBlock:
		    ^ (id obj, size_t idx, BOOL *stop) {
			    count++;
			    if (![obj isEqual: [cmp objectAtIndex: idx]])
				    ok = NO;
		}];

		if (count != [cmp count])
			ok = NO;

		TEST(@"Enumeration using blocks", ok)

		ok = NO;
		a2 = m[0];
		@try {
			[a2 enumerateObjectsUsingBlock:
			    ^ (id obj, size_t idx, BOOL *stop) {
				[a2 removeObjectAtIndex: idx];
			}];
		} @catch (OFEnumerationMutationException *e) {
			ok = YES;
			[e dealloc];
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    ok)
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([m[0] replaceObjectsUsingBlock:
	    ^ id (id obj, size_t idx, BOOL *stop) {
		switch (idx) {
		case 0:
			return @"foo";
		case 1:
			return @"bar";
		}

		return nil;
	    }]) && [[m[0] objectAtIndex: 0] isEqual: @"foo"] &&
	    [[m[0] objectAtIndex: 1] isEqual: @"bar"])
#endif

	[pool drain];
}
@end
