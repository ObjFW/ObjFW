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

#import "OFXMLElement.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFXMLElement";

@implementation TestsAppDelegate (OFXMLElementTests)
- (void)XMLElementTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *elem[2];

	TEST(@"+[elementWithName:]",
	    (elem[0] = [OFXMLElement elementWithName: @"foo"]) &&
	    [[elem[0] string] isEqual: @"<foo/>"])

	TEST(@"+[elementWithName:stringValue:]",
	    (elem[1] = [OFXMLElement elementWithName: @"foo"
					 stringValue: @"b&ar"]) &&
	    [[elem[1] string] isEqual: @"<foo>b&amp;ar</foo>"])

	TEST(@"-[addAttributeWithName:stringValue:]",
	    R([elem[0] addAttributeWithName: @"foo"
				stringValue: @"b&ar"]) &&
	    [[elem[0] string] isEqual: @"<foo foo='b&amp;ar'/>"] &&
	    R([elem[1] addAttributeWithName: @"foo"
				stringValue: @"b&ar"]) &&
	    [[elem[1] string] isEqual: @"<foo foo='b&amp;ar'>b&amp;ar</foo>"])

	TEST(@"-[addChild:]",
	    R([elem[0] addChild: [OFXMLElement elementWithName: @"bar"]]) &&
	    [[elem[0] string] isEqual: @"<foo foo='b&amp;ar'><bar/></foo>"])

	[pool drain];
}
@end
