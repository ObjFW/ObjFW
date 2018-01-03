/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFCharacterSet.h"
#import "OFCharacterSet_bitset.h"
#import "OFCharacterSet_range.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = nil;

@interface SimpleCharacterSet: OFCharacterSet
@end

@implementation SimpleCharacterSet
- (bool)characterIsMember: (of_unichar_t)character
{
	return (character % 2 == 0);
}
@end

@implementation TestsAppDelegate (OFCharacterSetTests)
- (void)characterSetTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFCharacterSet *cs, *ics;
	bool ok;

	module = @"OFCharacterSet";

	cs = [[[SimpleCharacterSet alloc] init] autorelease];

	ok = true;
	for (of_unichar_t c = 0; c < 65536; c++) {
		if (c % 2 == 0) {
			if (![cs characterIsMember: c])
				ok = false;
		} else if ([cs characterIsMember: c])
			ok = false;
	}
	TEST(@"-[characterIsMember:]", ok);

	module = @"OFCharacterSet_bitset";

	TEST(@"+[characterSetWithCharactersInString:]",
	    (cs = [OFCharacterSet characterSetWithCharactersInString:
	    @"0123456789"]) &&
	    [cs isKindOfClass: [OFCharacterSet_bitset class]])

	ok = true;
	for (of_unichar_t c = 0; c < 65536; c++) {
		if (c >= '0' && c <= '9') {
			if (![cs characterIsMember: c])
				ok = false;
		} else if ([cs characterIsMember: c])
			ok = false;
	}
	TEST(@"-[characterIsMember:]", ok);

	module = @"OFCharacterSet_range";

	TEST(@"+[characterSetWithRange:]",
	    (cs = [OFCharacterSet characterSetWithRange: of_range('0', 10)]) &&
	    [cs isKindOfClass: [OFCharacterSet_range class]])

	ok = true;
	for (of_unichar_t c = 0; c < 65536; c++) {
		if (c >= '0' && c <= '9') {
			if (![cs characterIsMember: c])
				ok = false;
		} else if ([cs characterIsMember: c])
			ok = false;
	}
	TEST(@"-[characterIsMember:]", ok);

	ok = true;
	ics = [cs invertedSet];
	for (of_unichar_t c = 0; c < 65536; c++) {
		if (c >= '0' && c <= '9') {
			if ([ics characterIsMember: c])
				ok = false;
		} else if (![ics characterIsMember: c])
			ok = false;
	}
	TEST(@"-[invertedSet]", ok);

	TEST(@"Inverting -[invertedSet] returns original set",
	    [ics invertedSet] == cs)

	[pool drain];
}
@end
