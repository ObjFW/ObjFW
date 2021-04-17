/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFColor.h"
#import "OFStdIOStream.h"
#import "OFThread.h"

@interface TerminalTests: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(TerminalTests)

@implementation TerminalTests
- (void)applicationDidFinishLaunching
{
	OFArray *colors = [OFArray arrayWithObjects:
	    [OFColor black], [OFColor silver], [OFColor grey], [OFColor white],
	    [OFColor maroon], [OFColor red], [OFColor purple],
	    [OFColor fuchsia], [OFColor green], [OFColor lime], [OFColor olive],
	    [OFColor yellow], [OFColor navy], [OFColor blue], [OFColor teal],
	    [OFColor aqua], nil];
	size_t i;
	OFEnumerator OF_GENERIC(OFColor *) *reverseEnumerator;

	[of_stdout writeFormat: @"%dx%d\n", of_stdout.columns, of_stdout.rows];

	i = 0;
	for (OFColor *color in colors) {
		[of_stdout setForegroundColor: color];
		[of_stdout writeFormat: @"%zx", i++];
	}
	[of_stdout reset];
	[of_stdout writeLine: @"R"];

	i = 0;
	for (OFColor *color in colors) {
		[of_stdout setBackgroundColor: color];
		[of_stdout writeFormat: @"%zx", i++];
	}
	[of_stdout reset];
	[of_stdout writeLine: @"R"];

	i = 0;
	reverseEnumerator = [colors.reversedArray objectEnumerator];
	for (OFColor *color in colors) {
		[of_stdout setForegroundColor: color];
		[of_stdout setBackgroundColor: [reverseEnumerator nextObject]];
		[of_stdout writeFormat: @"%zx", i++];
	}
	[of_stdout reset];
	[of_stdout writeLine: @"R"];

	for (i = 0; i < colors.count * 2; i++) {
		if (i % 2)
			[of_stdout setBackgroundColor: [colors objectAtIndex:
			    ((i / 2) + 2) % colors.count]];
		else
			[of_stdout setForegroundColor:
			    [colors objectAtIndex: i / 2]];

		[of_stdout writeFormat: @"%zx", i / 2];
	}
	[of_stdout reset];
	[of_stdout writeLine: @"R"];

	[of_stdout writeLine: @"Press return"];
	[of_stdin readLine];

	[of_stdout setBackgroundColor: [OFColor green]];
	[of_stdout writeString: @"Hello!"];
	[OFThread sleepForTimeInterval: 2];
	[of_stdout eraseLine];
	[of_stdout writeString: @"World!"];
	[OFThread sleepForTimeInterval: 2];

	[of_stdout clear];
	[OFThread sleepForTimeInterval: 2];

	[of_stdout setCursorPosition: OFPointMake(5, 3)];
	[of_stdout writeString: @"Text at (5, 3)"];
	[OFThread sleepForTimeInterval: 2];

	[of_stdout setRelativeCursorPosition: OFPointMake(-2, 0)];
	[OFThread sleepForTimeInterval: 2];
	[of_stdout setRelativeCursorPosition: OFPointMake(2, 0)];
	[OFThread sleepForTimeInterval: 2];
	[of_stdout setRelativeCursorPosition: OFPointMake(0, -2)];
	[OFThread sleepForTimeInterval: 2];
	[of_stdout setRelativeCursorPosition: OFPointMake(0, 2)];
	[OFThread sleepForTimeInterval: 2];
	[of_stdout setRelativeCursorPosition: OFPointMake(1, 1)];
	[OFThread sleepForTimeInterval: 2];
	[of_stdout setRelativeCursorPosition: OFPointMake(-1, -1)];
	[OFThread sleepForTimeInterval: 2];

	[of_stdout setCursorColumn: 2];
	[OFThread sleepForTimeInterval: 2];

	[of_stdout reset];

	[OFApplication terminate];
}
@end
