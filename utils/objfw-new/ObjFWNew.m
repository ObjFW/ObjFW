/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
extern void newClass(OFString *, OFString *, OFMutableArray *);

OF_APPLICATION_DELEGATE(ObjFWNew)

static void
showUsage(void)
{
	[OFStdErr writeFormat: @"Usage: %@ --app|--class name\n",
			       [OFApplication programName]];

	[OFApplication terminateWithStatus: 1];
}

@implementation ObjFWNew
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	bool app, class;
	OFString *superclass = nil, *name;
	OFMutableArray OF_GENERIC(OFString *) *properties = nil;
	const OFOptionsParserOption options[] = {
		{ 'a', @"app", 0, &app, NULL },
		{ 'c', @"class", 0, &class, NULL },
		{ 's', @"superclass", 1, NULL, &superclass },
		{ 'p', @"property", 1, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser;
	OFUnichar option;

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'p':
			if (properties == nil)
				properties = [OFMutableArray array];

			[properties addObject: optionsParser.argument];
			break;
		case '?':
		case ':':
		case '=':
			showUsage();
			break;
		}
	}

	if ((app ^ class) != 1 || optionsParser.remainingArguments.count != 1)
		showUsage();

	if ((superclass && !class)  || (properties != nil && !class))
		showUsage();

	name = optionsParser.remainingArguments.firstObject;
	if ([name rangeOfString: @"."].location != OFNotFound) {
		[OFStdErr writeLine: @"Name must not contain dots!"];
		[OFApplication terminate];
	}

	if (app)
		newApp(name);
	else if (class)
		newClass(name, superclass, properties);
	else
		showUsage();

	[OFApplication terminate];
}
@end
