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

@interface Subprocess: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(Subprocess)

@implementation Subprocess
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFString *line;

	if (![[OFApplication arguments] isEqual:
	    [OFArray arrayWithObjects: @"tést", @"123", nil]])
		[OFApplication terminateWithStatus: 1];

	if (![[[OFApplication environment] objectForKey: @"tëst"]
	    isEqual: @"yés"]) {
		[OFApplication terminateWithStatus: 2];
	}

#ifdef OF_WINDOWS
	/* On Windows 9x, closing the pipe doesn't seem to cause EOF. */
	if (![OFSystemInfo isWindowsNT]) {
		if ((line = [OFStdIn readLine]) != nil)
			[OFStdOut writeLine: line.uppercaseString];
	} else
#endif
		while ((line = [OFStdIn readLine]) != nil)
			[OFStdOut writeLine: line.uppercaseString];

	[OFApplication terminate];
}
@end
