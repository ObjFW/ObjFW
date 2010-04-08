/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdlib.h>

#import "OFApplication.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

OFApplication *app = nil;

static void
atexit_handler()
{
	id delegate = [app delegate];

	[delegate applicationWillTerminate];
}

int
of_application_main(int argc, char *argv[], Class cls)
{
	OFApplication *app;
	id delegate = nil;

	if (cls != Nil)
		delegate = [[cls alloc] init];

	app = [OFApplication sharedApplication];

	[app setArgumentCount: argc
	    andArgumentValues: argv];

	[app setDelegate: delegate];
	[delegate release];

	[app run];

	return 0;
}

@implementation OFApplication
+ sharedApplication
{
	if (app == nil)
		app = [[self alloc] init];

	return app;
}

+ (OFString*)programName
{
	return [app programName];
}

+ (OFArray*)arguments
{
	return [app arguments];
}

+ (void)terminate
{
	exit(0);
}

- init
{
	self = [super init];

	atexit(atexit_handler);

	return self;
}

-  setArgumentCount: (int)argc
  andArgumentValues: (char**)argv
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	int i;

	[progname release];
	[arguments release];

	progname = [[OFString alloc] initWithCString: argv[0]];
	arguments = [[OFMutableArray alloc] init];

	for (i = 1; i < argc; i++)
		[arguments addObject: [OFString stringWithCString: argv[i]]];

	[pool release];

	return self;
}

- (OFString*)programName
{
	return [[progname retain] autorelease];
}

- (OFArray*)arguments
{
	return [[arguments retain] autorelease];
}

- (id)delegate
{
	return [[delegate retain] autorelease];
}

- setDelegate: (id)delegate_
{
	id old = delegate;
	delegate = [delegate_ retain];
	[old release];

	return self;
}

- run
{
	[delegate applicationDidFinishLaunching];

	return self;
}

- (void)terminate
{
	exit(0);
}

- (void)dealloc
{
	[arguments release];
	[delegate release];

	[super dealloc];
}
@end

@implementation OFObject (OFApplicationDelegate)
- (void)applicationDidFinishLaunching
{
}

- (void)applicationWillTerminate
{
}
@end
