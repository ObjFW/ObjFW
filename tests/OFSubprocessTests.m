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

static OFString *const module = @"OFSubprocess";

@implementation TestsAppDelegate (OFSubprocessTests)
- (void)subprocessTests
{
	void *pool = objc_autoreleasePoolPush();
	OFString *program = [@"subprocess" stringByAppendingPathComponent:
	    @"subprocess" @PROG_SUFFIX];
	OFArray *arguments = [OFArray arrayWithObjects: @"tést", @"123", nil];
	OFMutableDictionary *environment =
	    [[[OFApplication environment] mutableCopy] autorelease];
	OFSubprocess *subprocess;

	[environment setObject: @"yés" forKey: @"tëst"];

	TEST(@"+[subprocessWithProgram:programName:arguments:environment]",
	    (subprocess =
	    [OFSubprocess subprocessWithProgram: program
				    programName: program
				      arguments: arguments
				    environment: environment]))

	TEST(@"Standard input", R([subprocess writeLine: @"Hellö world!"]))

	TEST(@"Standard output",
	    [[subprocess readLine] isEqual: @"HELLÖ WORLD!"])

	TEST(@"-[closeForWriting]", R([subprocess closeForWriting]))

	TEST(@"-[waitForTermination]", [subprocess waitForTermination] == 0)

	objc_autoreleasePoolPop(pool);
}
@end
