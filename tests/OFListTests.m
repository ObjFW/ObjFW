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
	OFListItem iter;
	OFString *object;
	size_t i;
	bool ok;

	TEST(@"+[list]", (list = [OFList list]))

	TEST(@"-[appendObject:]", [list appendObject: strings[0]] &&
	    [list appendObject: strings[1]] && [list appendObject: strings[2]])

	TEST(@"-[firstListItem]",
	    [OFListItemObject(list.firstListItem) isEqual: strings[0]])

	TEST(@"OFListItemNext()",
	    [OFListItemObject(OFListItemNext(list.firstListItem))
	    isEqual: strings[1]])

	TEST(@"-[lastListItem]",
	    [OFListItemObject(list.lastListItem) isEqual: strings[2]])

	TEST(@"OFListItemPrevious()",
	    [OFListItemObject(OFListItemPrevious(list.lastListItem))
	    isEqual: strings[1]])

	TEST(@"-[removeListItem:]",
	    R([list removeListItem: list.lastListItem]) &&
	    [list.lastObject isEqual: strings[1]] &&
	    R([list removeListItem: list.firstListItem]) &&
	    [list.firstObject isEqual: list.lastObject])

	TEST(@"-[insertObject:beforeListItem:]",
	    [list insertObject: strings[0] beforeListItem: list.lastListItem] &&
	    [OFListItemObject(OFListItemPrevious(list.lastListItem))
	    isEqual: strings[0]])

	TEST(@"-[insertObject:afterListItem:]",
	    [list insertObject: strings[2]
		 afterListItem: OFListItemNext(list.firstListItem)] &&
	    [list.lastObject isEqual: strings[2]])

	TEST(@"-[count]", list.count == 3)

	TEST(@"-[containsObject:]",
	    [list containsObject: strings[1]] &&
	    ![list containsObject: @"nonexistent"])

	TEST(@"-[containsObjectIdenticalTo:]",
	    [list containsObjectIdenticalTo: strings[1]] &&
	    ![list containsObjectIdenticalTo:
	    [OFString stringWithString: strings[1]]])

	TEST(@"-[copy]", (list = [[list copy] autorelease]) &&
	    [list.firstObject isEqual: strings[0]] &&
	    [OFListItemObject(OFListItemNext(list.firstListItem))
	    isEqual: strings[1]] &&
	    [list.lastObject isEqual: strings[2]])

	TEST(@"-[isEqual:]", [list isEqual: [[list copy] autorelease]])

	TEST(@"-[description]",
	    [list.description isEqual: @"[\n\tFoo,\n\tBar,\n\tBaz\n]"])

	TEST(@"-[objectEnumerator]", (enumerator = [list objectEnumerator]))

	iter = list.firstListItem;
	i = 0;
	ok = true;
	while ((object = [enumerator nextObject]) != nil) {
		if (![object isEqual: OFListItemObject(iter)])
			ok = false;

		iter = OFListItemNext(iter);
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

	for (OFString *object_ in list) {
		if (![object_ isEqual: OFListItemObject(iter)])
			ok = false;

		iter = OFListItemNext(iter);
		i++;
	}

	if (list.count != i)
		ok = false;

	TEST(@"Fast Enumeration", ok)

	ok = false;
	@try {
		for (OFString *object_ in list) {
			(void)object_;

			[list removeListItem: list.lastListItem];
		}
	} @catch (OFEnumerationMutationException *e) {
		ok = true;
	}

	TEST(@"Detection of mutation during Fast Enumeration", ok)

	objc_autoreleasePoolPop(pool);
}
@end
