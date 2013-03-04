/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <signal.h>

#import "OFApplication.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_THREADS
# import "OFThread.h"
#endif
#import "OFRunLoop.h"

#import "autorelease.h"
#import "macros.h"

#if defined(__MACH__) && !defined(OF_IOS)
# include <crt_externs.h>
#elif defined(_WIN32)
# include <windows.h>

extern int _CRT_glob;
extern void __wgetmainargs(int*, wchar_t***, wchar_t***, int, int*);
#elif !defined(OF_IOS)
extern char **environ;
#endif

static OFApplication *app = nil;

static void
atexit_handler(void)
{
	id <OFApplicationDelegate> delegate = [app delegate];

	if ([delegate respondsToSelector: @selector(applicationWillTerminate)])
		[delegate applicationWillTerminate];

	[delegate release];
}

#define SIGNAL_HANDLER(sig)					\
	static void						\
	handle##sig(int signal)					\
	{							\
		app->_##sig##Handler(app->_delegate,		\
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
	id <OFApplicationDelegate> delegate;
#ifdef _WIN32
	wchar_t **wargv, **wenvp;
	int wargc, si = 0;
#endif

	if ([cls isSubclassOfClass: [OFApplication class]]) {
		fprintf(stderr, "FATAL ERROR:\n  Class %s is a subclass of "
		    "class OFApplication, but class\n  %s was specified as "
		    "application delegate!\n  Most likely, you wanted to "
		    "subclass OFObject instead or specified\n  the wrong class "
		    "with OF_APPLICATION_DELEGATE().\n",
		    class_getName(cls), class_getName(cls));
		exit(1);
	}

	app = [[OFApplication alloc] init];

	[app OF_setArgumentCount: argc
	       andArgumentValues: argv];

#ifdef _WIN32
	__wgetmainargs(&wargc, &wargv, &wenvp, _CRT_glob, &si);
	[app OF_setArgumentCount: wargc
	   andWideArgumentValues: wargv];
#endif

	delegate = [[cls alloc] init];
	[app setDelegate: delegate];

	[app run];

	return 0;
}

@implementation OFApplication
+ (OFApplication*)sharedApplication
{
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
		OFMutableDictionary *environment;
#if defined(__MACH__) && !defined(OF_IOS)
		char **env = *_NSGetEnviron();
#elif defined(__WIN32)
		uint16_t *env;
#elif !defined(OF_IOS)
		char **env = environ;
#else
		char *env;
#endif

		environment = [[OFMutableDictionary alloc] init];

		atexit(atexit_handler);
#if defined(_WIN32)
		env = GetEnvironmentStringsW();

		while (*env != 0) {
			OFString *tmp, *key, *value;
			size_t length, pos;

			pool = objc_autoreleasePoolPush();

			length = of_string_utf16_length(env);
			tmp = [OFString stringWithUTF16String: env
						       length: length];
			env += length + 1;

			/*
			 * cmd.exe seems to add some special variables which
			 * start with a "=", even though variable names are not
			 * allowed to contain a "=".
			 */
			if ([tmp hasPrefix: @"="]) {
				objc_autoreleasePoolPop(pool);
				continue;
			}

			pos = [tmp rangeOfString: @"="].location;
			if (pos == OF_NOT_FOUND) {
				fprintf(stderr, "Warning: Invalid environment "
				    "variable: %s\n", [tmp UTF8String]);
				continue;
			}

			key = [tmp substringWithRange: of_range(0, pos)];
			value = [tmp substringWithRange:
			    of_range(pos + 1, [tmp length] - pos - 1)];

			[environment setObject: value
					forKey: key];

			objc_autoreleasePoolPop(pool);
		}

		FreeEnvironmentStringsW(env);
#elif !defined(OF_IOS)
		for (; *env != NULL; env++) {
			OFString *key, *value;
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
					freeWhenDone: false] autorelease];
			[environment setObject: home
					forKey: @"HOME"];
		}
		if ((env = getenv("PATH")) != NULL) {
			OFString *path = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: false] autorelease];
			[environment setObject: path
					forKey: @"PATH"];
		}
		if ((env = getenv("SHELL")) != NULL) {
			OFString *shell = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: false] autorelease];
			[environment setObject: shell
					forKey: @"SHELL"];
		}
		if ((env = getenv("TMPDIR")) != NULL) {
			OFString *tmpdir = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: false] autorelease];
			[environment setObject: tmpdir
					forKey: @"TMPDIR"];
		}
		if ((env = getenv("USER")) != NULL) {
			OFString *user = [[[OFString alloc]
			    initWithUTF8StringNoCopy: env
					freeWhenDone: false] autorelease];
			[environment setObject: user
					forKey: @"USER"];
		}

		objc_autoreleasePoolPop(pool);
#endif

		[environment makeImmutable];
		_environment = environment;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_arguments release];
	[_environment release];

	[super dealloc];
}

- (void)OF_setArgumentCount: (int*)argc
	  andArgumentValues: (char***)argv
{
#ifndef _WIN32
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *arguments;
	int i;

	_argc = argc;
	_argv = argv;

	_programName = [[OFString alloc]
	    initWithCString: (*argv)[0]
		   encoding: OF_STRING_ENCODING_NATIVE];
	arguments = [[OFMutableArray alloc] init];

	for (i = 1; i < *argc; i++)
		[arguments addObject:
		    [OFString stringWithCString: (*argv)[i]
				       encoding: OF_STRING_ENCODING_NATIVE]];

	[arguments makeImmutable];
	_arguments = arguments;

	objc_autoreleasePoolPop(pool);
#else
	_argc = argc;
	_argv = argv;
#endif
}

#ifdef _WIN32
- (void)OF_setArgumentCount: (int)argc
      andWideArgumentValues: (wchar_t**)argv
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *arguments;
	int i;

	_programName = [[OFString alloc] initWithUTF16String: argv[0]];
	arguments = [[OFMutableArray alloc] init];

	for (i = 1; i < argc; i++)
		[arguments addObject:
		    [OFString stringWithUTF16String: argv[i]]];

	[arguments makeImmutable];
	_arguments = arguments;

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)getArgumentCount: (int**)argc
       andArgumentValues: (char****)argv
{
	*argc = _argc;
	*argv = _argv;
}

- (OFString*)programName
{
	OF_GETTER(_programName, false)
}

- (OFArray*)arguments
{
	OF_GETTER(_arguments, false)
}

- (OFDictionary*)environment
{
	OF_GETTER(_environment, false)
}

- (id <OFApplicationDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate: (id <OFApplicationDelegate>)delegate
{
	_delegate = delegate;

#define REGISTER_SIGNAL(sig)						\
	if ([delegate respondsToSelector:				\
	    @selector(applicationDidReceive##sig)]) {			\
		_##sig##Handler = (void(*)(id, SEL))[(id)delegate	\
		    methodForSelector:					\
		    @selector(applicationDidReceive##sig)];		\
		signal(sig, handle##sig);				\
	} else								\
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

#ifdef OF_HAVE_THREADS
	[OFThread OF_createMainThread];
	runLoop = [OFRunLoop currentRunLoop];
#else
	runLoop = [[[OFRunLoop alloc] init] autorelease];
#endif

	[OFRunLoop OF_setMainRunLoop: runLoop];

	objc_autoreleasePoolPop(pool);

	/*
	 * Note: runLoop is still valid after the release of the pool, as
	 * OF_setMainRunLoop: retained it. However, we only have a weak
	 * reference to it now, whereas we had a strong reference before.
	 */

	pool = objc_autoreleasePoolPush();
	[_delegate applicationDidFinishLaunching];
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
@end
