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
	    isEqual: @"yés"])
		[OFApplication terminateWithStatus: 2];

	while ((line = [OFStdIn readLine]) != nil)
		[OFStdOut writeLine: line.uppercaseString];

	[OFApplication terminate];
}
@end
