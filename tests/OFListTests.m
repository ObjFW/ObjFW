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

#import "OFList.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

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

	TEST(@"+[list]", (list = [OFList list]))

	TEST(@"-[appendObject:]", [list appendObject: strings[0]] &&
	    [list appendObject: strings[1]] && [list appendObject: strings[2]])

	TEST(@"-[firstListObject]",
	    [[list firstListObject]->object isEqual: strings[0]])

	TEST(@"-[firstListObject]->next",
	    [[list firstListObject]->next->object isEqual: strings[1]])

	TEST(@"-[lastListObject]",
	    [[list lastListObject]->object isEqual: strings[2]])

	TEST(@"-[lastListObject]->prev",
	    [[list lastListObject]->prev->object isEqual: strings[1]])

	TEST(@"-[removeListObject:]",
	    R([list removeListObject: [list lastListObject]]) &&
	    [[list lastListObject]->object isEqual: strings[1]] &&
	    R([list removeListObject: [list firstListObject]]) &&
	    [[list firstListObject]->object isEqual:
	    [list lastListObject]->object])

	TEST(@"-[insertObject:beforeListObject:]",
	    [list insertObject: strings[0]
	      beforeListObject: [list lastListObject]] &&
	    [[list lastListObject]->prev->object isEqual: strings[0]])


	TEST(@"-[insertObject:afterListObject:]",
	    [list insertObject: strings[2]
	       afterListObject: [list firstListObject]->next] &&
	    [[list lastListObject]->object isEqual: strings[2]])

	TEST(@"-[count]", [list count] == 3)

	TEST(@"-[copy]", (list = [[list copy] autorelease]) &&
	    [[list firstListObject]->object isEqual: strings[0]] &&
	    [[list firstListObject]->next->object isEqual: strings[1]] &&
	    [[list lastListObject]->object isEqual: strings[2]])

	TEST(@"-[isEqual:]", [list isEqual: [[list copy] autorelease]])

	[pool drain];
}
@end
