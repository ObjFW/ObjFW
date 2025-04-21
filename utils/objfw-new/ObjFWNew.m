/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
#import "OFObject.h"
#import "OFOptionsParser.h"
#import "OFStdIOStream.h"
#import "OFString.h"

@interface ObjFWNew: OFObject <OFApplicationDelegate>
@end

extern void newApp(OFString *);
extern void newClass(OFString *, OFString *, OFMutableArray *);
extern void newTest(OFString *);

OF_APPLICATION_DELEGATE(ObjFWNew)

static void
help(OFStream *stream, bool full, int status)
{
	[stream writeFormat:
	    @"Usage: %@ --app|--class|--test [--superclass=] [--property=] name"
	    @"\n",
	    [OFApplication programName]];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine:
		    @"Options:\n"
		    @"    -a  --app          Create a new app\n"
		    @"    -c  --class        Create a new class\n"
		    @"    -h  --help         Show this help\n"
		    @"    -p  --property=    Add a property to the class.\n"
		    @"                       E.g.: --property='(readonly, "
		    @"nonatomic) id foo'\n"
		    @"    -s  --superclass=  Specify the superclass for the "
		    @"class\n"
		    @"    -t  --test         Create a new test\n"];
	}

	[OFApplication terminateWithStatus: status];
}

@implementation ObjFWNew
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	bool app, class, test;
	OFString *superclass = nil, *name;
	OFMutableArray OF_GENERIC(OFString *) *properties = nil;
	const OFOptionsParserOption options[] = {
		{ 'a', @"app", 0, &app, NULL },
		{ 'c', @"class", 0, &class, NULL },
		{ 'h', @"help", 0, NULL, NULL },
		{ 'p', @"property", 1, NULL, NULL },
		{ 's', @"superclass", 1, NULL, &superclass },
		{ 't', @"test", 0, &test, NULL },
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

	if (app + class + test != 1 ||
	    optionsParser.remainingArguments.count != 1)
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
	else if (test)
		newTest(name);
	else
		help(OFStdErr, false, 1);

	[OFApplication terminate];
}
@end
