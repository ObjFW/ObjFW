/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"Properties";

@interface PropertiesTest: OFObject
{
	OFString *foo;
	OFString *bar;
}

@property (copy, nonatomic) OFString *foo;
@property (retain) OFString *bar;
@end

@implementation PropertiesTest
@synthesize foo;
@synthesize bar;

- (void)dealloc
{
	[foo release];
	[bar release];

	[super dealloc];
}
@end

@implementation TestsAppDelegate (PropertiesTests)
- (void)propertiesTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	PropertiesTest *pt = [[[PropertiesTest alloc] init] autorelease];
	OFString *t = [OFMutableString stringWithString: @"foo"];
	OFString *foo = @"foo";

	[pt setFoo: t];
	TEST(@"copy, nonatomic", [[pt foo] isEqual: foo] &&
	    [pt foo] != foo && [[pt foo] retainCount] == 1)

	[pt setBar: t];
	TEST(@"retain, atomic", [pt bar] == t && [t retainCount] == 3)

	[pool drain];
}
@end
