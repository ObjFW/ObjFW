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
help(OFStream *stream, bool full, int status)
{
	[stream writeFormat:
	    @"Usage: %@ --app|--class [--superclass=] [--property=] name\n",
	    [OFApplication programName]];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine:
		    @"Options:\n"
		    @"    -a  --app          Create a new app\n"
		    @"    -c  --class        Create a new class\n"
		    @"    -h  --help         Show this help\n"
		    @"    -s  --superclass=  Specify the superclass for the "
		    @"class\n"
		    @"    -p  --property=    Add a property to the class.\n"
		    @"                       E.g.: --property='(readonly, "
		    @"nonatomic) id foo'"];
	}

	[OFApplication terminateWithStatus: status];
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
		{ 'h', @"help", 0, NULL, NULL },
		{ 's', @"superclass", 1, NULL, &superclass },
		{ 'p', @"property", 1, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser;
	OFUnichar option;

	if ([OFApplication arguments].count == 0)
		help(OFStdErr, true, 1);

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'h':
			help(OFStdOut, true, 0);
			break;
		case 'p':
			if (properties == nil)
				properties = [OFMutableArray array];

			[properties addObject: optionsParser.argument];
			break;
		case '?':
		case ':':
		case '=':
			help(OFStdErr, false, 1);
			break;
		}
	}

	if ((app ^ class) != 1 || optionsParser.remainingArguments.count != 1)
		help(OFStdErr, false, 1);

	if ((superclass && !class)  || (properties != nil && !class))
		help(OFStdErr, false, 1);

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
		help(OFStdErr, false, 1);

	[OFApplication terminate];
}
@end
