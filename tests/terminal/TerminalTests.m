/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
	    [OFColor black], [OFColor silver], [OFColor gray], [OFColor white],
	    [OFColor maroon], [OFColor red], [OFColor purple],
	    [OFColor fuchsia], [OFColor green], [OFColor lime], [OFColor olive],
	    [OFColor yellow], [OFColor navy], [OFColor blue], [OFColor teal],
	    [OFColor aqua], nil];
	size_t i;
	OFEnumerator OF_GENERIC(OFColor *) *reverseEnumerator;

	[OFStdOut writeFormat: @"%dx%d\n", OFStdOut.columns, OFStdOut.rows];

	i = 0;
	for (OFColor *color in colors) {
		OFStdOut.foregroundColor = color;
		[OFStdOut writeFormat: @"%zx", i++];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	i = 0;
	for (OFColor *color in colors) {
		OFStdOut.backgroundColor = color;
		[OFStdOut writeFormat: @"%zx", i++];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	i = 0;
	reverseEnumerator = [colors.reversedArray objectEnumerator];
	for (OFColor *color in colors) {
		OFStdOut.foregroundColor = color;
		OFStdOut.backgroundColor = [reverseEnumerator nextObject];
		[OFStdOut writeFormat: @"%zx", i++];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	for (i = 0; i < colors.count * 2; i++) {
		if (i % 2)
			OFStdOut.backgroundColor = [colors objectAtIndex:
			    ((i / 2) + 2) % colors.count];
		else
			OFStdOut.foregroundColor =
			    [colors objectAtIndex: i / 2];

		[OFStdOut writeFormat: @"%zx", i / 2];
	}
	[OFStdOut reset];
	[OFStdOut writeLine: @"R"];

	[OFStdOut writeLine: @"Press return"];
	[OFStdIn readLine];

	OFStdOut.backgroundColor = [OFColor green];
	[OFStdOut writeString: @"Hello!"];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut eraseLine];
	[OFStdOut writeString: @"World!"];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut clear];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut setCursorPosition: OFMakePoint(5.0f, 3.0f)];
	[OFStdOut writeString: @"Text at (5, 3)"];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut setRelativeCursorPosition: OFMakePoint(-2.0f, 0.0f)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(2.0f, 0.0f)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(0.0f, -2.0f)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(0.0f, 2.0f)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(1.0f, 1.0f)];
	[OFThread sleepForTimeInterval: 2];
	[OFStdOut setRelativeCursorPosition: OFMakePoint(-1.0f, -1.0f)];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut setCursorColumn: 2];
	[OFThread sleepForTimeInterval: 2];

	[OFStdOut reset];

	[OFApplication terminate];
}
@end
