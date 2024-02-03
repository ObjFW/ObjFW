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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFColor.h"
#import "OFStdIOStream.h"
#import "OFThread.h"

@interface TerminalTests: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(TerminalTests)

@implementation TerminalTests
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFArray *colors = [OFArray arrayWithObjects:
	    [OFColor black], [OFColor silver], [OFColor grey], [OFColor white],
	    [OFColor maroon], [OFColor red], [OFColor purple],
	    [OFColor fuchsia], [OFColor green], [OFColor lime], [OFColor olive],
	    [OFColor yellow], [OFColor navy], [OFColor blue], [OFColor teal],
	    [OFColor aqua], nil];
	size_t i;
	OFEnumerator OF_GENERIC(OFColor *) *reverseEnumerator;

	[OFStdOut writeFormat: @"%dx%d\n", OFStdOut.columns, OFStdOut.rows];

	i = 0;
	for (OFColor *color in colors) {
		[OFStdOut setForegroundColor: color];
		[OFStdOut writeFormat: @"%zx", i++];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	i = 0;
	for (OFColor *color in colors) {
		[OFStdOut setBackgroundColor: color];
		[OFStdOut writeFormat: @"%zx", i++];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	i = 0;
	reverseEnumerator = [colors.reversedArray objectEnumerator];
	for (OFColor *color in colors) {
		[OFStdOut setForegroundColor: color];
		[OFStdOut setBackgroundColor: [reverseEnumerator nextObject]];
		[OFStdOut writeFormat: @"%zx", i++];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	for (i = 0; i < colors.count * 2; i++) {
		if (i % 2)
			[OFStdOut setBackgroundColor: [colors objectAtIndex:
			    ((i / 2) + 2) % colors.count]];
		else
			[OFStdOut setForegroundColor:
			    [colors objectAtIndex: i / 2]];

		[OFStdOut writeFormat: @"%zx", i / 2];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	[OFStdOut writeLine: @"Press return"];
	[OFStdIn readLine];

	[OFStdOut setBackgroundColor: [OFColor green]];
	[OFStdOut writeString: @"Hello!"];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut eraseLine];
	[OFStdOut writeString: @"World!"];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut clear];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut setCursorPosition: OFMakePoint(5, 3)];
	[OFStdOut writeString: @"Text at (5, 3)"];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut setRelativeCursorPosition: OFMakePoint(-2, 0)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(2, 0)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(0, -2)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(0, 2)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(1, 1)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(-1, -1)];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut setCursorColumn: 2];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut reset];

	[OFApplication terminate];
}
@end
