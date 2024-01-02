/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFCharacterSet.h"
#import "OFBitSetCharacterSet.h"
#import "OFRangeCharacterSet.h"

static OFString *module;

@interface SimpleCharacterSet: OFCharacterSet
@end

@implementation SimpleCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	return (character % 2 == 0);
}
@end

@implementation TestsAppDelegate (OFCharacterSetTests)
- (void)characterSetTests
{
	void *pool = objc_autoreleasePoolPush();
	OFCharacterSet *characterSet, *invertedCharacterSet;
	bool ok;

	module = @"OFCharacterSet";

	characterSet = [[[SimpleCharacterSet alloc] init] autorelease];

	ok = true;
	for (OFUnichar c = 0; c < 65536; c++) {
		if (c % 2 == 0) {
			if (![characterSet characterIsMember: c])
				ok = false;
		} else if ([characterSet characterIsMember: c])
			ok = false;
	}
	TEST(@"-[characterIsMember:]", ok);

	module = @"OFBitSetCharacterSet";

	TEST(@"+[characterSetWithCharactersInString:]",
	    (characterSet = [OFCharacterSet characterSetWithCharactersInString:
	    @"0123456789"]) &&
	    [characterSet isKindOfClass: [OFBitSetCharacterSet class]])

	ok = true;
	for (OFUnichar c = 0; c < 65536; c++) {
		if (c >= '0' && c <= '9') {
			if (![characterSet characterIsMember: c])
				ok = false;
		} else if ([characterSet characterIsMember: c])
			ok = false;
	}
	TEST(@"-[characterIsMember:]", ok);

	module = @"OFRangeCharacterSet";

	TEST(@"+[characterSetWithRange:]",
	    (characterSet = [OFCharacterSet
	    characterSetWithRange: OFMakeRange('0', 10)]) &&
	    [characterSet isKindOfClass: [OFRangeCharacterSet class]])

	ok = true;
	for (OFUnichar c = 0; c < 65536; c++) {
		if (c >= '0' && c <= '9') {
			if (![characterSet characterIsMember: c])
				ok = false;
		} else if ([characterSet characterIsMember: c])
			ok = false;
	}
	TEST(@"-[characterIsMember:]", ok);

	ok = true;
	invertedCharacterSet = characterSet.invertedSet;
	for (OFUnichar c = 0; c < 65536; c++) {
		if (c >= '0' && c <= '9') {
			if ([invertedCharacterSet characterIsMember: c])
				ok = false;
		} else if (![invertedCharacterSet characterIsMember: c])
			ok = false;
	}
	TEST(@"-[invertedSet]", ok);

	TEST(@"Inverting -[invertedSet] returns original set",
	    invertedCharacterSet.invertedSet == characterSet)

	objc_autoreleasePoolPop(pool);
}
@end
