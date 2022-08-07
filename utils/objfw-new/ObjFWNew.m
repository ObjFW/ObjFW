/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#import "OFObject.h"
#import "OFStdIOStream.h"
#import "OFString.h"

@interface ObjFWNew: OFObject <OFApplicationDelegate>
@end

extern void newApp(OFString *);
extern void newClass(OFString *);

OF_APPLICATION_DELEGATE(ObjFWNew)

static void
showUsage(void)
{
	[OFStdErr writeFormat: @"Usage: %@ app|class name [properties]\n",
			       [OFApplication programName]];

	[OFApplication terminateWithStatus: 1];
}

@implementation ObjFWNew
- (void)applicationDidFinishLaunching
{
	OFArray OF_GENERIC(OFString *) *arguments = [OFApplication arguments];
	OFString *type, *name;

	if (arguments.count != 2)
		showUsage();

	type = [arguments objectAtIndex: 0];
	name = [arguments objectAtIndex: 1];

	if ([type isEqual: @"app"])
		newApp(name);
	else if ([type isEqual: @"class"])
		newClass(name);
	else
		showUsage();

	[OFApplication terminate];
}
@end
