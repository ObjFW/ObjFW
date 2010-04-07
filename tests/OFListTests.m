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

	TEST(@"-[append:]", [list append: strings[0]] &&
	    [list append: strings[1]] && [list append: strings[2]])

	TEST(@"-[first]", [[list first]->object isEqual: strings[0]])

	TEST(@"-[first]->next",
	    [[list first]->next->object isEqual: strings[1]])

	TEST(@"-[last]", [[list last]->object isEqual: strings[2]])

	TEST(@"-[last]->prev", [[list last]->prev->object isEqual: strings[1]])

	TEST(@"-[remove:]", [list remove: [list last]] &&
	    [[list last]->object isEqual: strings[1]] &&
	    [list remove: [list first]] &&
	    [[list first]->object isEqual: [list last]->object])

	TEST(@"-[insert:before:]", [list insert: strings[0]
					 before: [list last]] &&
	    [[list last]->prev->object isEqual: strings[0]])


	TEST(@"-[insert:after:]", [list insert: strings[2]
					 after: [list first]->next] &&
	    [[list last]->object isEqual: strings[2]])

	TEST(@"-[count]", [list count] == 3)

	TEST(@"-[copy]", (list = [[list copy] autorelease]) &&
	    [[list first]->object isEqual: strings[0]] &&
	    [[list first]->next->object isEqual: strings[1]] &&
	    [[list last]->object isEqual: strings[2]])

	TEST(@"-[isEqual:]", [list isEqual: [[list copy] autorelease]])

	[pool drain];
}
@end
