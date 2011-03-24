/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#define OF_APPLICATION_M

#include <stdlib.h>

#import "OFApplication.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

#include <string.h>

#ifdef __MACH__
# include <crt_externs.h>
#else
 extern char **environ;
#endif

static OFApplication *app = nil;

static void
atexit_handler()
{
	id <OFApplicationDelegate> delegate = [app delegate];

	[delegate applicationWillTerminate];
}

int
of_application_main(int *argc, char **argv[], Class cls)
{
	OFApplication *app = [OFApplication sharedApplication];
	id <OFApplicationDelegate> delegate = [[cls alloc] init];

	[app setArgumentCount: argc
	    andArgumentValues: argv];

	[app setDelegate: delegate];
	[(id)delegate release];

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

+ (OFDictionary*)environment
{
	return [app environment];
}

+ (void)terminate
{
	exit(0);
}

+ (void)terminateWithStatus: (int)status
{
	exit(status);
}

- init
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool;
		char **env;

		environment = [[OFMutableDictionary alloc] init];

		atexit(atexit_handler);
#ifdef __MACH__
		env = *_NSGetEnviron();
#else
		env = environ;
#endif

		pool = [[OFAutoreleasePool alloc] init];
		for (; *env != NULL; env++) {
			OFString *key;
			OFString *value;
			char *sep;

			if ((sep = strchr(*env, '=')) == NULL) {
				fprintf(stderr, "Warning: Invalid environment "
				    "variable: %s\n", *env);
				continue;
			}

			key = [OFString stringWithCString: *env
						   length: sep - *env];
			value = [OFString stringWithCString: sep + 1];
			[environment setObject: value
					forKey: key];

			[pool releaseObjects];
		}
		[pool release];

		/*
		 * Class swizzle the environment to be immutable, as we don't
		 * need to change it anymore and expose it only as
		 * OFDictionary*. But not swizzling it would create a real copy
		 * each time -[copy] is called.
		 */
		environment->isa = [OFDictionary class];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)setArgumentCount: (int*)argc_
       andArgumentValues: (char***)argv_
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	int i;

	[programName release];
	[arguments release];

	argc = argc_;
	argv = argv_;

	programName = [[OFString alloc] initWithCString: (*argv)[0]];
	arguments = [[OFMutableArray alloc] init];

	for (i = 1; i < *argc; i++)
		[arguments addObject: [OFString stringWithCString: (*argv)[i]]];

	/*
	 * Class swizzle the arguments to be immutable, as we don't need to
	 * change them anymore and expose them only as OFArray*. But not
	 * swizzling it would create a real copy each time -[copy] is called.
	 */
	arguments->isa = [OFArray class];

	[pool release];
}

- (void)getArgumentCount: (int**)argc_
       andArgumentValues: (char****)argv_
{
	*argc_ = argc;
	*argv_ = argv;
}

- (OFString*)programName
{
	return [[programName copy] autorelease];
}

- (OFArray*)arguments
{
	return [[arguments copy] autorelease];
}

- (OFDictionary*)environment
{
	return [[environment copy] autorelease];
}

- (id <OFApplicationDelegate>)delegate
{
	return [[(id)delegate retain] autorelease];
}

- (void)setDelegate: (id <OFApplicationDelegate>)delegate_
{
	[(id)delegate_ retain];
	[(id)delegate release];
	delegate = delegate_;
}

- (void)run
{
	[delegate applicationDidFinishLaunching];
}

- (void)terminate
{
	exit(0);
}

- (void)terminateWithStatus: (int)status
{
	exit(status);
}

- (void)dealloc
{
	[arguments release];
	[environment release];
	[(id)delegate release];

	[super dealloc];
}
@end

@implementation OFObject (OFApplicationDelegate)
- (void)applicationDidFinishLaunching
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)applicationWillTerminate
{
}
@end
