/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <signal.h>

#import "OFApplication.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFThread.h"
#import "OFRunLoop.h"

#import "OFNotImplementedException.h"

#import "autorelease.h"

#if defined(__MACH__) && !defined(OF_IOS)
# include <crt_externs.h>
#elif !defined(OF_IOS)
extern char **environ;
#endif

static OFApplication *app = nil;

static void
atexit_handler(void)
{
	id <OFApplicationDelegate> delegate = [app delegate];

	[delegate applicationWillTerminate];

	[(id)delegate release];
}

#define SIGNAL_HANDLER(sig)					\
	static void						\
	handle##sig(int signal)					\
	{							\
		app->sig##Handler(app->delegate,		\
		    @selector(applicationDidReceive##sig));	\
	}
SIGNAL_HANDLER(SIGINT)
#ifndef _WIN32
SIGNAL_HANDLER(SIGHUP)
SIGNAL_HANDLER(SIGUSR1)
SIGNAL_HANDLER(SIGUSR2)
#endif
#undef SIGNAL_HANDLER

int
of_application_main(int *argc, char **argv[], Class cls)
{
	OFApplication *app = [OFApplication sharedApplication];
	id <OFApplicationDelegate> delegate = [[cls alloc] init];

	[app setArgumentCount: argc
	    andArgumentValues: argv];

	[app setDelegate: delegate];

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
		void *pool;
#if defined(__MACH__) && !defined(OF_IOS)
		char **env = *_NSGetEnviron();
#elif !defined(OF_IOS)
		char **env = environ;
#else
		char *env;
#endif

		environment = [[OFMutableDictionary alloc] init];

		atexit(atexit_handler);
#ifndef OF_IOS
		for (; *env != NULL; env++) {
			OFString *key;
			OFString *value;
			char *sep;

			pool = objc_autoreleasePoolPush();

			if ((sep = strchr(*env, '=')) == NULL) {
				fprintf(stderr, "Warning: Invalid environment "
				    "variable: %s\n", *env);
				continue;
			}

			key = [OFString
			    stringWithCString: *env
				     encoding: OF_STRING_ENCODING_NATIVE
				       length: sep - *env];
			value = [OFString
			    stringWithCString: sep + 1
				     encoding: OF_STRING_ENCODING_NATIVE];
			[environment setObject: value
					forKey: key];

			objc_autoreleasePoolPop(pool);
		}
#else
		/*
		 * iOS does not provide environ and Apple does not allow using
		 * _NSGetEnviron on iOS. Therefore, we just get a few common
		 * variables from the environment which applications might
		 * expect.
		 */
		pool = objc_autoreleasePoolPush();

		if ((env = getenv("HOME")) != NULL) {
			OFString *home = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: NO] autorelease];
			[environment setObject: home
					forKey: @"HOME"];
		}
		if ((env = getenv("PATH")) != NULL) {
			OFString *path = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: NO] autorelease];
			[environment setObject: path
					forKey: @"PATH"];
		}
		if ((env = getenv("SHELL")) != NULL) {
			OFString *shell = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: NO] autorelease];
			[environment setObject: shell
					forKey: @"SHELL"];
		}
		if ((env = getenv("TMPDIR")) != NULL) {
			OFString *tmpdir = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: NO] autorelease];
			[environment setObject: tmpdir
					forKey: @"TMPDIR"];
		}
		if ((env = getenv("USER")) != NULL) {
			OFString *user = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: NO] autorelease];
			[environment setObject: user
					forKey: @"USER"];
		}

		objc_autoreleasePoolPop(pool);
#endif

		[environment makeImmutable];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)setArgumentCount: (int*)argc_
       andArgumentValues: (char***)argv_
{
	void *pool = objc_autoreleasePoolPush();
	int i;

	[programName release];
	[arguments release];

	argc = argc_;
	argv = argv_;

	programName = [[OFString alloc]
	    initWithCString: (*argv)[0]
		   encoding: OF_STRING_ENCODING_NATIVE];
	arguments = [[OFMutableArray alloc] init];

	for (i = 1; i < *argc; i++)
		[arguments addObject:
		    [OFString stringWithCString: (*argv)[i]
				       encoding: OF_STRING_ENCODING_NATIVE]];

	[arguments makeImmutable];

	objc_autoreleasePoolPop(pool);
}

- (void)getArgumentCount: (int**)argc_
       andArgumentValues: (char****)argv_
{
	*argc_ = argc;
	*argv_ = argv;
}

- (OFString*)programName
{
	return programName;
}

- (OFArray*)arguments
{
	return arguments;
}

- (OFDictionary*)environment
{
	return environment;
}

- (id <OFApplicationDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate: (id <OFApplicationDelegate>)delegate_
{
	delegate = delegate_;

#define REGISTER_SIGNAL(sig)						  \
	sig##Handler = (void(*)(id, SEL))[(id)delegate methodForSelector: \
	    @selector(applicationDidReceive##sig)];			  \
	if (sig##Handler != (void(*)(id, SEL))[OFObject			  \
	    instanceMethodForSelector:					  \
	    @selector(applicationDidReceive##sig)])			  \
		signal(sig, handle##sig);				  \
	else								  \
		signal(sig, SIG_DFL);
	REGISTER_SIGNAL(SIGINT)
#ifndef _WIN32
	REGISTER_SIGNAL(SIGHUP)
	REGISTER_SIGNAL(SIGUSR1)
	REGISTER_SIGNAL(SIGUSR2)
#endif
#undef REGISTER_SIGNAL
}

- (void)run
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop;

	[OFThread OF_createMainThread];
	runLoop = [OFRunLoop currentRunLoop];
	[OFRunLoop OF_setMainRunLoop];

	objc_autoreleasePoolPop(pool);

	pool = objc_autoreleasePoolPush();
	[delegate applicationDidFinishLaunching];
	objc_autoreleasePoolPop(pool);

	[runLoop run];
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

	[super dealloc];
}
@end

@implementation OFObject (OFApplicationDelegate)
- (void)applicationDidFinishLaunching
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (void)applicationWillTerminate
{
}

- (void)applicationDidReceiveSIGINT
{
}

- (void)applicationDidReceiveSIGHUP
{
}

- (void)applicationDidReceiveSIGUSR1
{
}

- (void)applicationDidReceiveSIGUSR2
{
}
@end
