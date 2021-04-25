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

static OFString *module = @"OFList";
static OFString *strings[] = {
	@"Foo",
	@"Bar",
	@"Baz"
};

@implementation TestsAppDelegate (OFListTests)
- (void)listTests
{
	void *pool = objc_autoreleasePoolPush();
	OFList *list;
	OFEnumerator *enumerator;
	OFListItem *iter;
	OFString *obj;
	size_t i;
	bool ok;

	TEST(@"+[list]", (list = [OFList list]))

	TEST(@"-[appendObject:]", [list appendObject: strings[0]] &&
	    [list appendObject: strings[1]] && [list appendObject: strings[2]])

	TEST(@"-[firstListItem]",
	    [list.firstListItem->object isEqual: strings[0]])

	TEST(@"-[firstListItem]->next",
	    [list.firstListItem->next->object isEqual: strings[1]])

	TEST(@"-[lastListItem]",
	    [list.lastListItem->object isEqual: strings[2]])

	TEST(@"-[lastListItem]->previous",
	    [list.lastListItem->previous->object isEqual: strings[1]])

	TEST(@"-[removeListItem:]",
	    R([list removeListItem: list.lastListItem]) &&
	    [list.lastListItem->object isEqual: strings[1]] &&
	    R([list removeListItem: list.firstListItem]) &&
	    [list.firstListItem->object isEqual: list.lastListItem->object])

	TEST(@"-[insertObject:beforeListItem:]",
	    [list insertObject: strings[0] beforeListItem: list.lastListItem] &&
	    [list.lastListItem->previous->object isEqual: strings[0]])

	TEST(@"-[insertObject:afterListItem:]",
	    [list insertObject: strings[2]
		 afterListItem: list.firstListItem->next] &&
	    [list.lastListItem->object isEqual: strings[2]])

	TEST(@"-[count]", list.count == 3)

	TEST(@"-[containsObject:]",
	    [list containsObject: strings[1]] &&
	    ![list containsObject: @"nonexistent"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [list containsObjectIdenticalTo: strings[1]] &&
	    ![list containsObjectIdenticalTo:
	    [OFString stringWithString: strings[1]]])

	TEST(@"-[copy]", (list = [[list copy] autorelease]) &&
	    [list.firstListItem->object isEqual: strings[0]] &&
	    [list.firstListItem->next->object isEqual: strings[1]] &&
	    [list.lastListItem->object isEqual: strings[2]])

	TEST(@"-[isEqual:]", [list isEqual: [[list copy] autorelease]])

	TEST(@"-[description]",
	    [list.description isEqual: @"[\n\tFoo,\n\tBar,\n\tBaz\n]"])

	TEST(@"-[objectEnumerator]", (enumerator = [list objectEnumerator]))

	iter = list.firstListItem;
	i = 0;
	ok = true;
	while ((obj = [enumerator nextObject]) != nil) {
		if (![obj isEqual: iter->object])
			ok = false;

		iter = iter->next;
		i++;
	}

	if (list.count != i)
		ok = false;

	TEST(@"OFEnumerator's -[nextObject]", ok);

	[list removeListItem: list.firstListItem];

	EXPECT_EXCEPTION(@"Detection of mutation during enumeration",
	    OFEnumerationMutationException, [enumerator nextObject])

	[list prependObject: strings[0]];

	iter = list.firstListItem;
	i = 0;
	ok = true;

	for (OFString *object in list) {
		if (![object isEqual: iter->object])
			ok = false;

		iter = iter->next;
		i++;
	}

	if (list.count != i)
		ok = false;

	TEST(@"Fast Enumeration", ok)

	ok = false;
	@try {
		for (OFString *object in list) {
			(void)object;

			[list removeListItem: list.lastListItem];
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	objc_autoreleasePoolPop(pool);
}
@end
