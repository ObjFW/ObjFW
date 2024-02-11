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
	OTAssertEqualObjects([subprocess readLine], @"HELLÖ WORLD!");

	[subprocess closeForWriting];

	OTAssertEqual([subprocess waitForTermination], 0);
}
@end
