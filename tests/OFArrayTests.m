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

static OFString *module;
static OFString *const cArray[] = {
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

- (instancetype)initWithObject: (id)object arguments: (va_list)arguments
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

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
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

- (void)insertObject: (id)object atIndex: (size_t)idx
{
	[_array insertObject: object atIndex: idx];
}

- (void)replaceObjectAtIndex: (size_t)idx withObject: (id)object
{
	[_array replaceObjectAtIndex: idx withObject: object];
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
	void *pool = objc_autoreleasePoolPush();
	OFArray *array1, *array2;
	OFMutableArray *mutableArray1, *mutableArray2;
	OFEnumerator *enumerator;
	id object;
	bool ok;
	size_t i;

	TEST(@"+[array]", (mutableArray1 = [mutableArrayClass array]))

	TEST(@"+[arrayWithObjects:]",
	    (array1 =
	    [arrayClass arrayWithObjects: @"Foo", @"Bar", @"Baz", nil]))

	TEST(@"+[arrayWithObjects:count:]",
	    (array2 = [arrayClass arrayWithObjects: cArray count: 3]) &&
	    [array2 isEqual: array1])

	TEST(@"-[description]",
	    [array1.description isEqual: @"(\n\tFoo,\n\tBar,\n\tBaz\n)"])

	TEST(@"-[addObject:]",
	    R([mutableArray1 addObject: cArray[0]]) &&
	    R([mutableArray1 addObject: cArray[2]]))

	TEST(@"-[insertObject:atIndex:]",
	    R([mutableArray1 insertObject: cArray[1] atIndex: 1]))

	TEST(@"-[count]",
	    mutableArray1.count == 3 && array1.count == 3 && array2.count == 3)

	TEST(@"-[isEqual:]",
	    [mutableArray1 isEqual: array1] && [array1 isEqual: array2])

	TEST(@"-[objectAtIndex:]",
	    [[mutableArray1 objectAtIndex: 0] isEqual: cArray[0]] &&
	    [[mutableArray1 objectAtIndex: 1] isEqual: cArray[1]] &&
	    [[mutableArray1 objectAtIndex: 2] isEqual: cArray[2]] &&
	    [[array1 objectAtIndex: 0] isEqual: cArray[0]] &&
	    [[array1 objectAtIndex: 1] isEqual: cArray[1]] &&
	    [[array1 objectAtIndex: 2] isEqual: cArray[2]] &&
	    [[array2 objectAtIndex: 0] isEqual: cArray[0]] &&
	    [[array2 objectAtIndex: 1] isEqual: cArray[1]] &&
	    [[array2 objectAtIndex: 2] isEqual: cArray[2]])

	TEST(@"-[containsObject:]",
	    [array1 containsObject: cArray[1]] &&
	    ![array1 containsObject: @"nonexistent"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [array1 containsObjectIdenticalTo: cArray[1]] &&
	    ![array1 containsObjectIdenticalTo:
	    [OFString stringWithString: cArray[1]]])

	TEST(@"-[indexOfObject:]", [array1 indexOfObject: cArray[1]] == 1)

	TEST(@"-[indexOfObjectIdenticalTo:]",
	    [array2 indexOfObjectIdenticalTo: cArray[1]] == 1)

	TEST(@"-[objectsInRange:]",
	    [[array1 objectsInRange: OFRangeMake(1, 2)] isEqual:
	    [arrayClass arrayWithObjects: cArray[1], cArray[2], nil]])

	TEST(@"-[replaceObject:withObject:]",
	    R([mutableArray1 replaceObject: cArray[1] withObject: cArray[0]]) &&
	    [[mutableArray1 objectAtIndex: 0] isEqual: cArray[0]] &&
	    [[mutableArray1 objectAtIndex: 1] isEqual: cArray[0]] &&
	    [[mutableArray1 objectAtIndex: 2] isEqual: cArray[2]])

	TEST(@"-[replaceObject:identicalTo:]",
	    R([mutableArray1 replaceObjectIdenticalTo: cArray[0]
					   withObject: cArray[1]]) &&
	    [[mutableArray1 objectAtIndex: 0] isEqual: cArray[1]] &&
	    [[mutableArray1 objectAtIndex: 1] isEqual: cArray[0]] &&
	    [[mutableArray1 objectAtIndex: 2] isEqual: cArray[2]])

	TEST(@"-[replaceObjectAtIndex:withObject:]",
	    R([mutableArray1 replaceObjectAtIndex: 0 withObject: cArray[0]]) &&
	    [[mutableArray1 objectAtIndex: 0] isEqual: cArray[0]] &&
	    [[mutableArray1 objectAtIndex: 1] isEqual: cArray[0]] &&
	    [[mutableArray1 objectAtIndex: 2] isEqual: cArray[2]])

	TEST(@"-[removeObject:]",
	    R([mutableArray1 removeObject: cArray[0]]) &&
	    mutableArray1.count == 2)

	TEST(@"-[removeObjectIdenticalTo:]",
	    R([mutableArray1 removeObjectIdenticalTo: cArray[2]]) &&
	    mutableArray1.count == 1)

	mutableArray2 = [[array1 mutableCopy] autorelease];
	TEST(@"-[removeObjectAtIndex:]",
	    R([mutableArray2 removeObjectAtIndex: 1]) &&
	    mutableArray2.count == 2 &&
	    [[mutableArray2 objectAtIndex: 1] isEqual: cArray[2]])

	mutableArray2 = [[array1 mutableCopy] autorelease];
	TEST(@"-[removeObjectsInRange:]",
	    R([mutableArray2 removeObjectsInRange: OFRangeMake(0, 2)]) &&
	    mutableArray2.count == 1 &&
	    [[mutableArray2 objectAtIndex: 0] isEqual: cArray[2]])

	mutableArray2 = [[array1 mutableCopy] autorelease];
	[mutableArray2 addObject: @"qux"];
	[mutableArray2 addObject: @"last"];
	TEST(@"-[reverse]",
	    R([mutableArray2 reverse]) &&
	    [mutableArray2 isEqual: [arrayClass arrayWithObjects:
	    @"last", @"qux", @"Baz", @"Bar", @"Foo", nil]])

	mutableArray2 = [[array1 mutableCopy] autorelease];
	[mutableArray2 addObject: @"qux"];
	[mutableArray2 addObject: @"last"];
	TEST(@"-[reversedArray]",
	    [[mutableArray2 reversedArray] isEqual:
	    [arrayClass arrayWithObjects:
	    @"last", @"qux", @"Baz", @"Bar", @"Foo", nil]])

	mutableArray2 = [[array1 mutableCopy] autorelease];
	[mutableArray2 addObject: @"0"];
	[mutableArray2 addObject: @"z"];
	TEST(@"-[sortedArray]",
	    [[mutableArray2 sortedArray] isEqual: [arrayClass arrayWithObjects:
	    @"0", @"Bar", @"Baz", @"Foo", @"z", nil]] &&
	    [[mutableArray2 sortedArrayUsingSelector: @selector(compare:)
					     options: OFArraySortDescending]
	    isEqual: [arrayClass arrayWithObjects:
	    @"z", @"Foo", @"Baz", @"Bar", @"0", nil]])

	EXPECT_EXCEPTION(@"Detect out of range in -[objectAtIndex:]",
	    OFOutOfRangeException, [array1 objectAtIndex: array1.count])

	EXPECT_EXCEPTION(@"Detect out of range in -[removeObjectsInRange:]",
	    OFOutOfRangeException, [mutableArray1 removeObjectsInRange:
		OFRangeMake(0, mutableArray1.count + 1)])

	TEST(@"-[componentsJoinedByString:]",
	    (array2 = [arrayClass arrayWithObjects: @"", @"a", @"b", @"c",
	    nil]) &&
	    [[array2 componentsJoinedByString: @" "] isEqual: @" a b c"] &&
	    (array2 = [arrayClass arrayWithObject: @"foo"]) &&
	    [[array2 componentsJoinedByString: @" "] isEqual: @"foo"])

	TEST(@"-[componentsJoinedByString:options]",
	    (array2 = [arrayClass arrayWithObjects: @"", @"foo", @"", @"",
	    @"bar", @"", nil]) &&
	    [[array2 componentsJoinedByString: @" "
				      options: OFArraySkipEmptyComponents]
	    isEqual: @"foo bar"])

	mutableArray1 = [[array1 mutableCopy] autorelease];
	ok = true;
	i = 0;

	TEST(@"-[objectEnumerator]",
	    (enumerator = [mutableArray1 objectEnumerator]))

	while ((object = [enumerator nextObject]) != nil) {
		if (![object isEqual: cArray[i]])
			ok = false;
		[mutableArray1 replaceObjectAtIndex: i withObject: @""];
		i++;
	}

	if (mutableArray1.count != i)
		ok = false;

	TEST(@"OFEnumerator's -[nextObject]", ok)

	[mutableArray1 removeObjectAtIndex: 0];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [enumerator nextObject])

	mutableArray1 = [[array1 mutableCopy] autorelease];
	ok = true;
	i = 0;

	for (OFString *string in mutableArray1) {
		if (![string isEqual: cArray[i]])
			ok = false;
		[mutableArray1 replaceObjectAtIndex: i withObject: @""];
		i++;
	}

	if (mutableArray1.count != i)
		ok = false;

	TEST(@"Fast Enumeration", ok)

	[mutableArray1 replaceObjectAtIndex: 0 withObject: cArray[0]];
	[mutableArray1 replaceObjectAtIndex: 1 withObject: cArray[1]];
	[mutableArray1 replaceObjectAtIndex: 2 withObject: cArray[2]];

	ok = false;
	i = 0;
	@try {
		for (OFString *string in mutableArray1) {
			(void)string;

			if (i == 0)
				[mutableArray1 addObject: @""];

			i++;
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[mutableArray1 removeLastObject];

#ifdef OF_HAVE_BLOCKS
	{
		__block bool blockOK = true;
		__block size_t count = 0;
		OFArray *compareArray = array1;
		OFMutableArray *mutableArray3;

		mutableArray1 = [[array1 mutableCopy] autorelease];
		[mutableArray1 enumerateObjectsUsingBlock:
		    ^ (id object_, size_t idx, bool *stop) {
			count++;
			if (![object_ isEqual:
			    [compareArray objectAtIndex: idx]])
				blockOK = false;
		}];

		if (count != compareArray.count)
			blockOK = false;

		TEST(@"Enumeration using blocks", blockOK)

		blockOK = false;
		mutableArray3 = mutableArray1;
		@try {
			[mutableArray3 enumerateObjectsUsingBlock:
			    ^ (id object_, size_t idx, bool *stop) {
				[mutableArray3 removeObjectAtIndex: idx];
			}];
		} @catch (OFEnumerationMutationException *e) {
			blockOK = true;
		} @catch (OFOutOfRangeException *e) {
			/*
			 * Out of bounds access due to enumeration not being
			 * detected.
			 */
		}

		TEST(@"Detection of mutation during enumeration using blocks",
		    blockOK)
	}

	TEST(@"-[replaceObjectsUsingBlock:]",
	    R([mutableArray1 replaceObjectsUsingBlock:
		^ id (id object_, size_t idx) {
		    switch (idx) {
		    case 0:
			    return @"foo";
		    case 1:
			    return @"bar";
		    }

		    return nil;
	    }]) && [mutableArray1.description isEqual: @"(\n\tfoo,\n\tbar\n)"])

	TEST(@"-[mappedArrayUsingBlock:]",
	    [[mutableArray1 mappedArrayUsingBlock:
		^ id (id object_, size_t idx) {
		    switch (idx) {
		    case 0:
			    return @"foobar";
		    case 1:
			    return @"qux";
		    }

		    return nil;
	    }].description isEqual: @"(\n\tfoobar,\n\tqux\n)"])

	TEST(@"-[filteredArrayUsingBlock:]",
	    [[mutableArray1 filteredArrayUsingBlock:
		^ bool (id object_, size_t idx) {
		    return [object_ isEqual: @"foo"];
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
	    [arrayClass arrayWithObjects: [OFNumber numberWithInt: 3],
	    [OFNumber numberWithInt: 3], [OFNumber numberWithInt: 6], nil]] &&
	    [[[arrayClass arrayWithObjects: @"1", @"2", nil]
	    valueForKey: @"@count"] isEqual: [OFNumber numberWithInt: 2]])

	mutableArray1 = [mutableArrayClass arrayWithObjects:
	    [OFMutableURL URLWithString: @"http://foo.bar/"],
	    [OFMutableURL URLWithString: @"http://bar.qux/"],
	    [OFMutableURL URLWithString: @"http://qux.quxqux/"], nil];
	TEST(@"-[setValue:forKey:]",
	    R([mutableArray1 setValue: [OFNumber numberWithShort: 1234]
			       forKey: @"port"]) &&
	    [mutableArray1 isEqual: [arrayClass arrayWithObjects:
	    [OFURL URLWithString: @"http://foo.bar:1234/"],
	    [OFURL URLWithString: @"http://bar.qux:1234/"],
	    [OFURL URLWithString: @"http://qux.quxqux:1234/"], nil]])

	objc_autoreleasePoolPop(pool);
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
