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

#import "ObjFW.h"
#import "ObjFWTest.h"

#import "OFCharacterSet.h"
#import "OFBitSetCharacterSet.h"
#import "OFRangeCharacterSet.h"

@interface OFCharacterSetTests: OTTestCase
@end

@interface CustomCharacterSet: OFCharacterSet
@end

@implementation CustomCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	return (character % 2 == 0);
}
@end

@implementation OFCharacterSetTests
- (void)testCustomCharacterSet
{
	OFCharacterSet *characterSet =
	    [[[CustomCharacterSet alloc] init] autorelease];

	for (OFUnichar c = 0; c < 65536; c++)
		if (c % 2 == 0)
			OTAssertTrue([characterSet characterIsMember: c]);
		else
			OTAssertFalse([characterSet characterIsMember: c]);
}

- (void)testBitSetCharacterSet
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithCharactersInString: @"0123456789"];

	OTAssertTrue(
	    [characterSet isKindOfClass: [OFBitSetCharacterSet class]]);

	for (OFUnichar c = 0; c < 65536; c++)
		if (c >= '0' && c <= '9')
			OTAssertTrue([characterSet characterIsMember: c]);
		else if ([characterSet characterIsMember: c])
			OTAssertFalse([characterSet characterIsMember: c]);
}

- (void)testRangeCharacterSet
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithRange: OFMakeRange('0', 10)];

	OTAssertTrue(
	    [characterSet isKindOfClass: [OFRangeCharacterSet class]]);

	for (OFUnichar c = 0; c < 65536; c++)
		if (c >= '0' && c <= '9')
			OTAssertTrue([characterSet characterIsMember: c]);
		else
			OTAssertFalse([characterSet characterIsMember: c]);
}

- (void)testInvertedCharacterSet
{
	OFCharacterSet *characterSet = [[OFCharacterSet
	    characterSetWithRange: OFMakeRange('0', 10)] invertedSet];

	for (OFUnichar c = 0; c < 65536; c++)
		if (c >= '0' && c <= '9')
			OTAssertFalse([characterSet characterIsMember: c]);
		else
			OTAssertTrue([characterSet characterIsMember: c]);
}

- (void)testInvertingInvertedSetReturnsOriginal
{
	OFCharacterSet *characterSet =
	    [OFCharacterSet characterSetWithRange: OFMakeRange('0', 10)];

	OTAssertEqual(characterSet, characterSet.invertedSet.invertedSet);
}
@end
