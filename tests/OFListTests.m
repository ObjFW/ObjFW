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

static OFString *module = @"OFList";
static OFString *strings[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@implementation TestsAppDelegate (OFListTests)
- (void)listTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFList *list;
	OFEnumerator *enumerator;
	of_list_object_t *loe;
	OFString *obj;
	size_t i;
	bool ok;

	TEST(@"+[list]", (list = [OFList list]))

	TEST(@"-[appendObject:]", [list appendObject: strings[0]] &&
	    [list appendObject: strings[1]] && [list appendObject: strings[2]])

	TEST(@"-[firstListObject]",
	    [list.firstListObject->object isEqual: strings[0]])

	TEST(@"-[firstListObject]->next",
	    [list.firstListObject->next->object isEqual: strings[1]])

	TEST(@"-[lastListObject]",
	    [list.lastListObject->object isEqual: strings[2]])

	TEST(@"-[lastListObject]->previous",
	    [list.lastListObject->previous->object isEqual: strings[1]])

	TEST(@"-[removeListObject:]",
	    R([list removeListObject: list.lastListObject]) &&
	    [list.lastListObject->object isEqual: strings[1]] &&
	    R([list removeListObject: list.firstListObject]) &&
	    [list.firstListObject->object isEqual: list.lastListObject->object])

	TEST(@"-[insertObject:beforeListObject:]",
	    [list insertObject: strings[0]
	      beforeListObject: list.lastListObject] &&
	    [list.lastListObject->previous->object isEqual: strings[0]])

	TEST(@"-[insertObject:afterListObject:]",
	    [list insertObject: strings[2]
	       afterListObject: list.firstListObject->next] &&
	    [list.lastListObject->object isEqual: strings[2]])

	TEST(@"-[count]", list.count == 3)

	TEST(@"-[containsObject:]",
	    [list containsObject: strings[1]] &&
	    ![list containsObject: @"nonexistent"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [list containsObjectIdenticalTo: strings[1]] &&
	    ![list containsObjectIdenticalTo:
	    [OFString stringWithString: strings[1]]])

	TEST(@"-[copy]", (list = [[list copy] autorelease]) &&
	    [list.firstListObject->object isEqual: strings[0]] &&
	    [list.firstListObject->next->object isEqual: strings[1]] &&
	    [list.lastListObject->object isEqual: strings[2]])

	TEST(@"-[isEqual:]", [list isEqual: [[list copy] autorelease]])

	TEST(@"-[description]",
	    [list.description isEqual: @"[\n\tFoo,\n\tBar,\n\tBaz\n]"])

	TEST(@"-[objectEnumerator]", (enumerator = [list objectEnumerator]))

	loe = list.firstListObject;
	i = 0;
	ok = true;
	while ((obj = [enumerator nextObject]) != nil) {
		if (![obj isEqual: loe->object])
			ok = false;

		loe = loe->next;
		i++;
	}

	if (list.count != i)
		ok = false;

	TEST(@"OFEnumerator's -[nextObject]", ok);

	[list removeListObject: list.firstListObject];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [enumerator nextObject])

	[list prependObject: strings[0]];

	loe = list.firstListObject;
	i = 0;
	ok = true;

	for (OFString *object in list) {
		if (![object isEqual: loe->object])
			ok = false;

		loe = loe->next;
		i++;
	}

	if (list.count != i)
		ok = false;

	TEST(@"Fast Enumeration", ok)

	ok = false;
	@try {
		for (OFString *object in list) {
			(void)object;

			[list removeListObject: list.lastListObject];
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	[pool drain];
}
@end
