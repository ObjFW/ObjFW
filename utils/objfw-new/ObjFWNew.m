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
#import "OFOptionsParser.h"
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
	[OFStdErr writeFormat: @"Usage: %@ --app|--class name\n",
			       [OFApplication programName]];

	[OFApplication terminateWithStatus: 1];
}

@implementation ObjFWNew
- (void)applicationDidFinishLaunching
{
	bool app, class;
	const OFOptionsParserOption options[] = {
		{ '\0', @"app", 0, &app, NULL },
		{ '\0', @"class", 0, &class, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser;
	OFUnichar option;

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0')
		if (option == '?')
			showUsage();

	if ((app ^ class) != 1 || optionsParser.remainingArguments.count != 1)
		showUsage();

	if (app)
		newApp(optionsParser.remainingArguments.firstObject);
	else if (class)
		newClass(optionsParser.remainingArguments.firstObject);
	else
		showUsage();

	[OFApplication terminate];
}
@end
