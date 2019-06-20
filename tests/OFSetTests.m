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

#import "OFSet.h"
#import "OFMapTableSet.h"
#import "OFMutableMapTableSet.h"

static OFString *module = nil;

@interface SimpleSet: OFSet
{
	OFMutableSet *_set;
}
@end

@interface SimpleMutableSet: OFMutableSet
{
	OFMutableSet *_set;
	unsigned long _mutations;
}
@end

@implementation SimpleSet
- (instancetype)init
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSet: (OFSet *)set
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithSet: set];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithArray: (OFArray *)array
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithArray: array];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	self = [super init];

	@try {
		_set = [[OFMutableSet alloc] initWithObject: firstObject
						  arguments: arguments];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_set release];

	[super dealloc];
}

- (size_t)count
{
	return _set.count;
}

- (bool)containsObject: (id)object
{
	return [_set containsObject: object];
}

- (OFEnumerator *)objectEnumerator
{
	return [_set objectEnumerator];
}
@end

@implementation SimpleMutableSet
+ (void)initialize
{
	if (self == [SimpleMutableSet class])
		[self inheritMethodsFromClass: [SimpleSet class]];
}

- (void)addObject: (id)object
{
	bool existed = [self containsObject: object];

	[_set addObject: object];

	if (existed)
		_mutations++;
}

- (void)removeObject: (id)object
{
	bool existed = [self containsObject: object];

	[_set removeObject: object];

	if (existed)
		_mutations++;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	int ret = [_set countByEnumeratingWithState: state
					    objects: objects
					      count: count];

	state->mutationsPtr = &_mutations;

	return ret;
}
@end

@implementation TestsAppDelegate (OFSetTests)
- (void)setTestsWithClass: (Class)setClass
	     mutableClass: (Class)mutableSetClass
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFSet *set1, *set2;
	OFMutableSet *mutableSet;
	bool ok;
	size_t i;

	TEST(@"+[setWithArray:]",
	    (set1 = [setClass setWithArray: [OFArray arrayWithObjects: @"foo",
	    @"bar", @"baz", @"foo", @"x", nil]]))

	TEST(@"+[setWithObjects:]",
	    (set2 = [setClass setWithObjects: @"foo", @"bar", @"baz", @"bar",
	    @"x", nil]))

	TEST(@"-[isEqual:]", [set1 isEqual: set2])

	TEST(@"-[hash]", set1.hash == set2.hash)

	TEST(@"-[description]",
	    [set1.description
	    isEqual: @"{(\n\tx,\n\tbar,\n\tfoo,\n\tbaz\n)}"] &&
	    [set1.description isEqual: set2.description])

	TEST(@"-[copy]", [set1 isEqual: [[set1 copy] autorelease]])

	TEST(@"-[mutableCopy]",
	    [set1 isEqual: [[set1 mutableCopy] autorelease]]);

	mutableSet = [mutableSetClass setWithSet: set1];

	TEST(@"-[addObject:]",
	    R([mutableSet addObject: @"baz"]) && [mutableSet isEqual: set2] &&
	    R([mutableSet addObject: @"y"]) && [mutableSet isEqual:
	    [setClass setWithObjects: @"foo", @"bar", @"baz", @"x", @"y", nil]])

	TEST(@"-[removeObject:]",
	    R([mutableSet removeObject: @"y"]) && [mutableSet isEqual: set1])

	TEST(@"-[isSubsetOfSet:]",
	    R([mutableSet removeObject: @"foo"]) &&
	    [mutableSet isSubsetOfSet: set1] &&
	    ![set1 isSubsetOfSet: mutableSet]);

	TEST(@"-[intersectsSet:]",
	    [(set2 = [setClass setWithObjects: @"x", nil])
	    intersectsSet: set1] && [set1 intersectsSet: set2] &&
	    ![[setClass setWithObjects: @"1", nil] intersectsSet: set1]);

	TEST(@"-[minusSet:]",
	    R([mutableSet minusSet: [setClass setWithObjects: @"x", nil]]) &&
	    [mutableSet isEqual: [setClass setWithObjects:
	    @"baz", @"bar", nil]])

	TEST(@"-[intersectSet:]",
	    R([mutableSet intersectSet: [setClass setWithObjects:
	    @"baz", nil]]) && [mutableSet isEqual: [setClass setWithObjects:
	    @"baz", nil]])

	TEST(@"-[unionSet:]",
	    R([mutableSet unionSet: [setClass setWithObjects:
	    @"x", @"bar", nil]]) && [mutableSet isEqual:
	    [setClass setWithObjects: @"baz", @"bar", @"x", nil]])

	TEST(@"-[removeAllObjects]",
	    R([mutableSet removeAllObjects]) &&
	    [mutableSet isEqual: [setClass set]])

	ok = true;
	i = 0;

	for (OFString *s in set1) {
		switch (i) {
		case 0:
			if (![s isEqual: @"x"])
				ok = false;
			break;
		case 1:
			if (![s isEqual: @"bar"])
				ok = false;
			break;
		case 2:
			if (![s isEqual: @"foo"])
				ok = false;
			break;
		case 3:
			if (![s isEqual: @"baz"])
				ok = false;
			break;
		}

		i++;
	}

	if (i != 4)
		ok = false;

	TEST(@"Fast enumeration", ok)

	ok = false;
	[mutableSet addObject: @"foo"];
	[mutableSet addObject: @"bar"];
	@try {
		for (OFString *s in mutableSet)
			[mutableSet removeObject: s];
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok);

	TEST(@"-[valueForKey:]",
	    [(set1 = [[setClass setWithObjects: @"a", @"ab", @"abc", @"b", nil]
	    valueForKey: @"length"]) isEqual: [setClass setWithObjects:
	    [OFNumber numberWithSize: 1], [OFNumber numberWithSize: 2],
	    [OFNumber numberWithSize: 3], nil]] &&
	    [[set1 valueForKey: @"@count"] isEqual:
	    [OFNumber numberWithSize: 3]])

	[pool drain];
}

- (void)setTests
{
	module = @"OFSet";
	[self setTestsWithClass: [SimpleSet class]
		   mutableClass: [SimpleMutableSet class]];

	module = @"OFMapTableSet";
	[self setTestsWithClass: [OFMapTableSet class]
		   mutableClass: [OFMutableMapTableSet class]];
}
@end
