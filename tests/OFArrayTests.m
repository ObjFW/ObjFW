/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "TestsAppDelegate.h"

static OFString *module = nil;
static OFString *c_ary[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@interface SimpleArray: OFArray
{
	OFMutableArray *_array;
}
@end

@interface SimpleMutableArray: OFMutableArray
{
	OFMutableArray *_array;
}
@end

@implementation SimpleArray
- (instancetype)init
{
	self = [super init];

	@try {
		_array = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)object
		     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		_array = [[OFMutableArray alloc] initWithObject: object
						      arguments: arguments];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	self = [super init];

	@try {
		_array = [[OFMutableArray alloc] initWithObjects: objects
							   count: count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_array release];

	[super dealloc];
}

- (id)objectAtIndex: (size_t)idx
{
	return [_array objectAtIndex: idx];
}

- (size_t)count
{
	return [_array count];
}
@end

@implementation SimpleMutableArray
+ (void)initialize
{
	if (self == [SimpleMutableArray class])
		[self inheritMethodsFromClass: [SimpleArray class]];
}

- (void)insertObject: (id)object
	     atIndex: (size_t)idx
{
	[_array insertObject: object
		     atIndex: idx];
}

- (void)replaceObjectAtIndex: (size_t)idx
		  withObject: (id)object
{
	[_array replaceObjectAtIndex: idx
			  withObject: object];
}

- (void)removeObjectAtIndex: (size_t)idx
{
	[_array removeObjectAtIndex: idx];
}
@end

@implementation TestsAppDelegate (OFArrayTests)
- (void)arrayTestsWithClass: (Class)arrayClass
	       mutableClass: (Class)mutableArrayClass
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *a[3];
	OFMutableArray *m[2];
	OFEnumerator *enumerator;
	id obj;
	bool ok;
	size_t i;

	TEST(@"+[array]", (m[0] = [mutableArrayClass array]))

	TEST(@"+[arrayWithObjects:]",
	    (a[0] = [arrayClass arrayWithObjects: @"Foo", @"Bar", @"Baz", nil]))

	TEST(@"+[arrayWithObjects:count:]",
	    (a[1] = [arrayClass arrayWithObjects: c_ary
					   count: 3]) &&
	    [a[1] isEqual: a[0]])

	TEST(@"-[description]",
	    [a[0].description isEqual: @"(\n\tFoo,\n\tBar,\n\tBaz\n)"])

	TEST(@"-[addObject:]", R([m[0] addObject: c_ary[0]]) &&
	    R([m[0] addObject: c_ary[2]]))

	TEST(@"-[insertObject:atIndex:]", R([m[0] insertObject: c_ary[1]
						       atIndex: 1]))

	TEST(@"-[count]", m[0].count == 3 && a[0].count == 3 && a[1].count == 3)

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
	    ![a[0] containsObject: @"nonexistent"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [a[0] containsObjectIdenticalTo: c_ary[1]] &&
	    ![a[0] containsObjectIdenticalTo:
	    [OFString stringWithString: c_ary[1]]])

	TEST(@"-[indexOfObject:]", [a[0] indexOfObject: c_ary[1]] == 1)

	TEST(@"-[indexOfObjectIdenticalTo:]",
	    [a[1] indexOfObjectIdenticalTo: c_ary[1]] == 1)

	TEST(@"-[objectsInRange:]",
	    [[a[0] objectsInRange: of_range(1, 2)] isEqual:
	    [arrayClass arrayWithObjects: c_ary[1], c_ary[2], nil]])

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
	    R([m[0] removeObject: c_ary[0]]) && m[0].count == 2)

	TEST(@"-[removeObjectIdenticalTo:]",
	    R([m[0] removeObjectIdenticalTo: c_ary[2]]) && m[0].count == 1)

	m[1] = [[a[0] mutableCopy] autorelease];
	TEST(@"-[removeObjectAtIndex:]", R([m[1] removeObjectAtIndex: 1]) &&
	    m[1].count == 2 && [[m[1] objectAtIndex: 1] isEqual: c_ary[2]])

	m[1] = [[a[0] mutableCopy] autorelease];
	TEST(@"-[removeObjectsInRange:]",
	    R([m[1] removeObjectsInRange: of_range(0, 2)]) &&
	    m[1].count == 1 && [[m[1] objectAtIndex: 0] isEqual: c_ary[2]])

	m[1] = [[a[0] mutableCopy] autorelease];
	[m[1] addObject: @"qux"];
	[m[1] addObject: @"last"];
	TEST(@"-[reverse]",
	    R([m[1] reverse]) && [m[1] isEqual: [arrayClass arrayWithObjects:
	    @"last", @"qux", @"Baz", @"Bar", @"Foo", nil]])

	m[1] = [[a[0] mutableCopy] autorelease];
	[m[1] addObject: @"qux"];
	[m[1] addObject: @"last"];
	TEST(@"-[reversedArray]",
	    [[m[1] reversedArray] isEqual: [arrayClass arrayWithObjects:
	    @"last", @"qux", @"Baz", @"Bar", @"Foo", nil]])

	m[1] = [[a[0] mutableCopy] autorelease];
	[m[1] addObject: @"0"];
	[m[1] addObject: @"z"];
	TEST(@"-[sortedArray]",
	    [[m[1] sortedArray] isEqual: [arrayClass arrayWithObjects:
	    @"0", @"Bar", @"Baz", @"Foo", @"z", nil]] &&
	    [[m[1] sortedArrayUsingSelector: @selector(compare:)
				    options: OF_ARRAY_SORT_DESCENDING]
	    isEqual: [arrayClass arrayWithObjects:
	    @"z", @"Foo", @"Baz", @"Bar", @"0", nil]])

	EXPECT_EXCEPTION(@"Detect out of range in -[objectAtIndex:]",
	    OFOutOfRangeException, [a[0] objectAtIndex: a[0].count])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeObjectsInRange:]",
	    OFOutOfRangeException, [m[0] removeObjectsInRange:
		of_range(0, m[0].count + 1)])

	TEST(@"-[componentsJoinedByString:]",
	    (a[1] = [arrayClass arrayWithObjects: @"", @"a", @"b", @"c",
	    nil]) &&
	    [[a[1] componentsJoinedByString: @" "] isEqual: @" a b c"] &&
	    (a[1] = [arrayClass arrayWithObject: @"foo"]) &&
	    [[a[1] componentsJoinedByString: @" "] isEqual: @"foo"])

	TEST(@"-[componentsJoinedByString:options]",
	    (a[1] = [arrayClass arrayWithObjects: @"", @"foo", @"", @"", @"bar",
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

	if (m[0].count != i)
		ok = false;

	TEST(@"OFEnumerator's -[nextObject]", ok)

	[m[0] removeObjectAtIndex: 0];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [enumerator nextObject])

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

	if (m[0].count != i)
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

#ifdef OF_HAVE_BLOCKS
	{
		__block bool blockOk = true;
		__block size_t count = 0;
		OFArray *cmp = a[0];
		OFMutableArray *a2;

		m[0] = [[a[0] mutableCopy] autorelease];
		[m[0] enumerateObjectsUsingBlock:
		    ^ (id object, size_t idx, bool *stop) {
			    count++;
			    if (![object isEqual: [cmp objectAtIndex: idx]])
				    blockOk = false;
		}];

		if (count != cmp.count)
			blockOk = false;

		TEST(@"Enumeration using blocks", blockOk)

		blockOk = false;
		a2 = m[0];
		@try {
			[a2 enumerateObjectsUsingBlock:
			    ^ (id object, size_t idx, bool *stop) {
				[a2 removeObjectAtIndex: idx];
			}];
		} @catch (OFEnumerationMutationException *e) {
			blockOk = true;
		} @catch (OFOutOfRangeException *e) {
			/*
			 * Out of bounds access due to enumeration not being
			 * detected.
			 */
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    blockOk)
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([m[0] replaceObjectsUsingBlock: ^ id (id object, size_t idx) {
		switch (idx) {
		case 0:
			return @"foo";
		case 1:
			return @"bar";
		}

		return nil;
	    }]) && [m[0].description isEqual: @"(\n\tfoo,\n\tbar\n)"])

	TEST(@"-[mappedArrayUsingBlock:]",
	    [[m[0] mappedArrayUsingBlock: ^ id (id object, size_t idx) {
		switch (idx) {
		case 0:
			return @"foobar";
		case 1:
			return @"qux";
		}

		return nil;
	    }].description isEqual: @"(\n\tfoobar,\n\tqux\n)"])

	TEST(@"-[filteredArrayUsingBlock:]",
	    [[m[0] filteredArrayUsingBlock: ^ bool (id object, size_t idx) {
		return [object isEqual: @"foo"];
	    }].description isEqual: @"(\n\tfoo\n)"])

	TEST(@"-[foldUsingBlock:]",
	    [[arrayClass arrayWithObjects: [OFMutableString string], @"foo",
	    @"bar", @"baz", nil] foldUsingBlock: ^ id (id left, id right) {
		[left appendString: right];
		return left;
	    }])
#endif

	TEST(@"-[valueForKey:]",
	    [[[arrayClass arrayWithObjects: @"foo", @"bar", @"quxqux", nil]
	    valueForKey: @"length"] isEqual:
	    [arrayClass arrayWithObjects: [OFNumber numberWithSize: 3],
	    [OFNumber numberWithSize: 3], [OFNumber numberWithSize: 6], nil]] &&
	    [[[arrayClass arrayWithObjects: @"1", @"2", nil]
	    valueForKey: @"@count"] isEqual: [OFNumber numberWithSize: 2]])

	m[0] = [mutableArrayClass arrayWithObjects:
	    [OFMutableURL URLWithString: @"http://foo.bar/"],
	    [OFMutableURL URLWithString: @"http://bar.qux/"],
	    [OFMutableURL URLWithString: @"http://qux.quxqux/"], nil];
	TEST(@"-[setValue:forKey:]",
	    R([m[0] setValue: [OFNumber numberWithShort: 1234]
		      forKey: @"port"]) &&
	    [m[0] isEqual: [arrayClass arrayWithObjects:
	    [OFURL URLWithString: @"http://foo.bar:1234/"],
	    [OFURL URLWithString: @"http://bar.qux:1234/"],
	    [OFURL URLWithString: @"http://qux.quxqux:1234/"], nil]])

	[pool drain];
}

- (void)arrayTests
{
	module = @"OFArray";
	[self arrayTestsWithClass: [SimpleArray class]
		     mutableClass: [SimpleMutableArray class]];

	module = @"OFArray_adjacent";
	[self arrayTestsWithClass: [OFArray class]
		     mutableClass: [OFMutableArray class]];
}
@end
