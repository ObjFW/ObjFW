/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
	    objc_autorelease([[CustomCharacterSet alloc] init]);

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
