/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@interface OFSubprocessTests: OTTestCase
@end

@implementation OFSubprocessTests
- (void)testSubprocess
{
#ifdef OF_HAVE_FILES
	OFString *program = [@"subprocess" stringByAppendingPathComponent:
	    @"subprocess" @PROG_SUFFIX];
#else
	OFString *program = @"subprocess/subprocess" @PROG_SUFFIX;
#endif
	OFArray *arguments = [OFArray arrayWithObjects: @"tést", @"123", nil];
	OFMutableDictionary *environment =
	    [[[OFApplication environment] mutableCopy] autorelease];
	OFSubprocess *subprocess;

	[environment setObject: @"yés" forKey: @"tëst"];

	subprocess = [OFSubprocess subprocessWithProgram: program
					     programName: program
					       arguments: arguments
					     environment: environment];

	[subprocess writeLine: @"Hellö world!"];
#ifdef OF_HAVE_UNICODE_TABLES
	OTAssertEqualObjects([subprocess readLine], @"HELLÖ WORLD!");
#else
	OTAssertEqualObjects([subprocess readLine], @"HELLö WORLD!");
#endif

	[subprocess closeForWriting];

	OTAssertEqual([subprocess waitForTermination], 0);
}
@end
