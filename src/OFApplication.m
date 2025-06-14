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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <errno.h>
#include <signal.h>

#include "unistd_wrapper.h"

#import "OFApplication.h"
#import "OFArray.h"
#import "OFDictionary.h"
#ifdef OF_AMIGAOS
# import "OFFile.h"
# import "OFFileManager.h"
#endif
#import "OFLocale.h"
#import "OFNotificationCenter.h"
#import "OFPair.h"
#import "OFRunLoop+Private.h"
#import "OFRunLoop.h"
#import "OFSandbox.h"
#ifdef OF_HAVE_SOCKETS
# import "OFSocket.h"
# import "OFSocket+Private.h"
#endif
#import "OFStdIOStream.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFThread+Private.h"
#import "OFThread.h"

#import "OFActivateSandboxFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#if defined(OF_MACOS)
# include <crt_externs.h>
#elif defined(OF_WINDOWS)
# include <windows.h>
#elif defined(OF_AMIGAOS)
# define Class IntuitionClass
# include <proto/exec.h>
# include <proto/dos.h>
# undef Class
#elif !defined(OF_IOS)
extern char **environ;
#endif

#ifdef OF_PSP
# include <pspkerneltypes.h>
# include <psploadexec.h>
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
#endif

OF_DIRECT_MEMBERS
@interface OFApplication ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
- (void)of_setArgumentCount: (int *)argc andArgumentValues: (char **[])argv;
#ifdef OF_WINDOWS
- (void)of_setArgumentCount: (int *)argc
	  andArgumentValues: (char **[])argv
       andWideArgumentCount: (int)wargc
      andWideArgumentValues: (wchar_t *[])wargv;
#endif
- (void)of_run;
@end

const OFNotificationName OFApplicationDidFinishLaunchingNotification =
    @"OFApplicationDidFinishLaunchingNotification";
const OFNotificationName OFApplicationWillTerminateNotification =
    @"OFApplicationWillTerminateNotification";
static OFApplication *app = nil;

static void
atexitHandler(void)
{
	id <OFApplicationDelegate> delegate = app.delegate;
	OFNotification *notification = [OFNotification
	    notificationWithName: OFApplicationWillTerminateNotification
			  object: app];

	if ([delegate respondsToSelector: @selector(applicationWillTerminate:)])
		[delegate applicationWillTerminate: notification];

	objc_release(delegate);

	[[OFNotificationCenter defaultCenter] postNotification: notification];

#if defined(OF_HAVE_THREADS) && defined(OF_HAVE_SOCKETS) && \
    defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
	_OFSocketDeinit();
#endif
}

int
OFApplicationMain(int *argc, char **argv[], id <OFApplicationDelegate> delegate)
{
	[OFLocale currentLocale];

	app = [[OFApplication alloc] of_init];

#ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT]) {
		extern void __wgetmainargs(int *, wchar_t ***, wchar_t ***, int,
		    int *);
		extern int _CRT_glob;
		wchar_t **wargv, **wenvp;
		int wargc, si = 0;

		__wgetmainargs(&wargc, &wargv, &wenvp, _CRT_glob, &si);

		[app of_setArgumentCount: argc
		       andArgumentValues: argv
		    andWideArgumentCount: wargc
		   andWideArgumentValues: wargv];
	} else
#endif
		[app of_setArgumentCount: argc andArgumentValues: argv];

	app.delegate = delegate;

	[app of_run];

	objc_release(delegate);

	return 0;
}

@implementation OFApplication
@synthesize programName = _programName, arguments = _arguments;
@synthesize environment = _environment;
#ifdef OF_HAVE_SANDBOX
@synthesize activeSandbox = _activeSandbox;
@synthesize activeSandboxForChildProcesses = _activeSandboxForChildProcesses;
#endif

#ifndef OF_AMIGAOS
# define SIGNAL_HANDLER(signal)					\
	static void						\
	handle##signal(int sig)					\
	{							\
		app->_##signal##Handler(app->_delegate,		\
		    @selector(applicationDidReceive##signal));	\
	}
SIGNAL_HANDLER(SIGINT)
# ifdef SIGHUP
SIGNAL_HANDLER(SIGHUP)
# endif
# ifdef SIGUSR1
SIGNAL_HANDLER(SIGUSR1)
# endif
# ifdef SIGUSR2
SIGNAL_HANDLER(SIGUSR2)
# endif
# undef SIGNAL_HANDLER
#endif

+ (OFApplication *)sharedApplication
{
	return app;
}

+ (OFString *)programName
{
	return app.programName;
}

+ (OFArray *)arguments
{
	return app.arguments;
}

+ (OFDictionary *)environment
{
	return app.environment;
}

+ (void)terminate
{
	[self terminateWithStatus: EXIT_SUCCESS];

	OF_UNREACHABLE
}

+ (void)terminateWithStatus: (int)status
{
#ifndef OF_PSP
	exit(status);

	OF_UNREACHABLE
#else
	sceKernelExitGame();

	OF_UNREACHABLE
#endif
}

#ifdef OF_HAVE_SANDBOX
+ (void)of_activateSandbox: (OFSandbox *)sandbox
{
	[app of_activateSandbox: sandbox];
}

+ (void)of_activateSandboxForChildProcesses: (OFSandbox *)sandbox
{
	[app of_activateSandboxForChildProcesses: sandbox];
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	self = [super init];

	@try {
		_environment = [[OFMutableDictionary alloc] init];

		atexit(atexitHandler);

#if defined(OF_WINDOWS)
		if ([OFSystemInfo isWindowsNT]) {
			OFChar16 *env, *env0;
			env = env0 = GetEnvironmentStringsW();

			while (*env != 0) {
				void *pool = objc_autoreleasePoolPush();
				OFString *tmp, *key, *value;
				size_t length, pos;

				length = OFUTF16StringLength(env);
				tmp = [OFString stringWithUTF16String: env
							       length: length];
				env += length + 1;

				/*
				 * cmd.exe seems to add some special variables
				 * which start with a "=", even though variable
				 * names are not allowed to contain a "=".
				 */
				if ([tmp hasPrefix: @"="]) {
					objc_autoreleasePoolPop(pool);
					continue;
				}

				pos = [tmp rangeOfString: @"="].location;
				if (pos == OFNotFound) {
					OFLog(@"Warning: Invalid environment "
					    "variable: %@", tmp);
					continue;
				}

				key = [tmp substringToIndex: pos];
				value = [tmp substringFromIndex: pos + 1];
				[_environment setObject: value forKey: key];

				objc_autoreleasePoolPop(pool);
			}

			FreeEnvironmentStringsW(env0);
		} else {
			char *env, *env0;
			env = env0 = GetEnvironmentStringsA();

			while (*env != 0) {
				void *pool = objc_autoreleasePoolPush();
				OFString *tmp, *key, *value;
				size_t length, pos;

				length = strlen(env);
				tmp = [OFString
				    stringWithCString: env
					     encoding: [OFLocale encoding]
					       length: length];
				env += length + 1;

				/*
				 * cmd.exe seems to add some special variables
				 * which start with a "=", even though variable
				 * names are not allowed to contain a "=".
				 */
				if ([tmp hasPrefix: @"="]) {
					objc_autoreleasePoolPop(pool);
					continue;
				}

				pos = [tmp rangeOfString: @"="].location;
				if (pos == OFNotFound) {
					OFLog(@"Warning: Invalid environment "
					    "variable: %@", tmp);
					continue;
				}

				key = [tmp substringToIndex: pos];
				value = [tmp substringFromIndex: pos + 1];
				[_environment setObject: value forKey: key];

				objc_autoreleasePoolPop(pool);
			}

			FreeEnvironmentStringsA(env0);
		}
#elif defined(OF_AMIGAOS)
		void *pool = objc_autoreleasePoolPush();
		OFFileManager *fileManager = [OFFileManager defaultManager];
		OFArray *envContents =
		    [fileManager contentsOfDirectoryAtPath: @"ENV:"];
		OFStringEncoding encoding = [OFLocale encoding];
		struct Process *proc;
		struct LocalVar *firstLocalVar;

		for (OFString *name in envContents) {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *path, *value;
			OFFile *file;

			if ([name containsString: @"."])
				continue;

			path = [@"ENV:" stringByAppendingString: name];

			if ([fileManager directoryExistsAtPath: path])
				continue;

			file = [OFFile fileWithPath: path mode: @"r"];

			value = [file readLineWithEncoding: encoding];
			if (value != nil)
				[_environment setObject: value forKey: name];

			objc_autoreleasePoolPop(pool2);
		}

		/* Local variables override global variables */
		proc = (struct Process *)FindTask(NULL);
		firstLocalVar = (struct LocalVar *)proc->pr_LocalVars.mlh_Head;

		for (struct LocalVar *iter = firstLocalVar;
		    iter->lv_Node.ln_Succ != NULL;
		    iter = (struct LocalVar *)iter->lv_Node.ln_Succ) {
# ifdef OF_AMIGAOS4
			int32 length;
# else
			ULONG length;
# endif
			OFString *key, *value;

			if (iter->lv_Node.ln_Type != LV_VAR ||
			    iter->lv_Flags & GVF_BINARY_VAR)
				continue;

			for (length = 0; length < iter->lv_Len; length++)
				if (iter->lv_Value[length] == 0)
					break;

			key = [OFString stringWithCString: iter->lv_Node.ln_Name
						 encoding: encoding];
			value = [OFString
			    stringWithCString: (const char *)iter->lv_Value
				     encoding: encoding
				       length: length];
			[_environment setObject: value forKey: key];
		}

		objc_autoreleasePoolPop(pool);
#elif !defined(OF_IOS)
# ifndef OF_MACOS
		char **env = environ;
# else
		char **env = *_NSGetEnviron();
# endif

		if (env != NULL) {
			OFStringEncoding encoding = [OFLocale encoding];

			for (; *env != NULL; env++) {
				void *pool = objc_autoreleasePoolPush();
				OFString *key, *value;
				char *sep;

				if ((sep = strchr(*env, '=')) == NULL) {
					OFLog(@"Warning: Invalid environment "
					    "variable: %s", *env);
					continue;
				}

				key = [OFString
				    stringWithCString: *env
					     encoding: encoding
					       length: sep - *env];
				value = [OFString
				    stringWithCString: sep + 1
					     encoding: encoding];
				[_environment setObject: value forKey: key];

				objc_autoreleasePoolPop(pool);
			}
		}
#else
		/*
		 * iOS does not provide environ and Apple does not allow using
		 * _NSGetEnviron on iOS. Therefore, we just get a few common
		 * variables from the environment which applications might
		 * expect.
		 */

		void *pool = objc_autoreleasePoolPush();
		char *env;

		if ((env = getenv("HOME")) != NULL) {
			OFString *home =
			    [OFString stringWithUTF8StringNoCopy: env
						    freeWhenDone: false];
			[_environment setObject: home forKey: @"HOME"];
		}
		if ((env = getenv("PATH")) != NULL) {
			OFString *path =
			    [OFString stringWithUTF8StringNoCopy: env
						    freeWhenDone: false];
			[_environment setObject: path forKey: @"PATH"];
		}
		if ((env = getenv("SHELL")) != NULL) {
			OFString *shell =
			    [OFString stringWithUTF8StringNoCopy: env
						    freeWhenDone: false];
			[_environment setObject: shell forKey: @"SHELL"];
		}
		if ((env = getenv("TMPDIR")) != NULL) {
			OFString *tmpdir =
			    [OFString stringWithUTF8StringNoCopy: env
						    freeWhenDone: false];
			[_environment setObject: tmpdir forKey: @"TMPDIR"];
		}
		if ((env = getenv("USER")) != NULL) {
			OFString *user =
			    [OFString stringWithUTF8StringNoCopy: env
						    freeWhenDone: false];
			[_environment setObject: user forKey: @"USER"];
		}

		objc_autoreleasePoolPop(pool);
#endif

		[_environment makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_arguments);
	objc_release(_environment);

	[super dealloc];
}

- (void)of_setArgumentCount: (int *)argc andArgumentValues: (char **[])argv
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *arguments;
	OFStringEncoding encoding;

	_argc = argc;
	_argv = argv;

	encoding = [OFLocale encoding];

#ifndef OF_NINTENDO_DS
	if (*argc > 0) {
#else
	if (g_envNdsArgvHeader->magic == ENV_NDS_ARGV_MAGIC &&
	    g_envNdsArgvHeader->argc > 0) {
#endif
		_programName = [[OFString alloc] initWithCString: (*argv)[0]
							encoding: encoding];
		arguments = [[OFMutableArray alloc] init];
		_arguments = arguments;

		for (int i = 1; i < *argc; i++)
			[arguments addObject:
			    [OFString stringWithCString: (*argv)[i]
					       encoding: encoding]];

		[arguments makeImmutable];
	}

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_WINDOWS
- (void)of_setArgumentCount: (int *)argc
	  andArgumentValues: (char **[])argv
       andWideArgumentCount: (int)wargc
      andWideArgumentValues: (wchar_t *[])wargv
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *arguments;

	_argc = argc;
	_argv = argv;

	if (wargc > 0) {
		_programName = [[OFString alloc] initWithUTF16String: wargv[0]];
		arguments = [[OFMutableArray alloc] init];

		for (int i = 1; i < wargc; i++)
			[arguments addObject:
			    [OFString stringWithUTF16String: wargv[i]]];

		[arguments makeImmutable];
		_arguments = arguments;
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- (void)getArgumentCount: (int **)argc andArgumentValues: (char ****)argv
{
	*argc = _argc;
	*argv = _argv;
}

- (id <OFApplicationDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate: (id <OFApplicationDelegate>)delegate
{
	_delegate = delegate;

#ifndef OF_AMIGAOS
# define REGISTER_SIGNAL(sig)						\
	if ([delegate respondsToSelector:				\
	    @selector(applicationDidReceive##sig)]) {			\
		_##sig##Handler = (void (*)(id, SEL))[(id)delegate	\
		    methodForSelector:					\
		    @selector(applicationDidReceive##sig)];		\
		signal(sig, handle##sig);				\
	} else {							\
		_##sig##Handler = NULL;					\
		signal(sig, (void (*)(int))SIG_DFL);			\
	}

	REGISTER_SIGNAL(SIGINT)
# ifdef SIGHUP
	REGISTER_SIGNAL(SIGHUP)
# endif
# ifdef SIGUSR1
	REGISTER_SIGNAL(SIGUSR1)
# endif
# ifdef SIGUSR2
	REGISTER_SIGNAL(SIGUSR2)
# endif

# undef REGISTER_SIGNAL
#endif
}

- (void)of_run
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop;
	OFNotification *notification;

#ifdef OF_HAVE_THREADS
	[OFThread of_createMainThread];
	runLoop = [OFRunLoop currentRunLoop];
#else
	runLoop = objc_autorelease([[OFRunLoop alloc] init]);
#endif

	[OFRunLoop of_setMainRunLoop: runLoop];

	objc_autoreleasePoolPop(pool);

	/*
	 * Note: runLoop is still valid after the release of the pool, as
	 * of_setMainRunLoop: retained it. However, we only have a weak
	 * reference to it now, whereas we had a strong reference before.
	 */

	pool = objc_autoreleasePoolPush();

	notification = [OFNotification
	    notificationWithName: OFApplicationDidFinishLaunchingNotification
			  object: app];

	[[OFNotificationCenter defaultCenter] postNotification: notification];

	[_delegate applicationDidFinishLaunching: notification];

	objc_autoreleasePoolPop(pool);

	[runLoop run];
}

- (void)terminate
{
	[self.class terminate];

	OF_UNREACHABLE
}

- (void)terminateWithStatus: (int)status
{
	[self.class terminateWithStatus: status];

	OF_UNREACHABLE
}

#ifdef OF_HAVE_SANDBOX
- (void)of_activateSandbox: (OFSandbox *)sandbox
{
# ifdef OF_HAVE_PLEDGE
	void *pool = objc_autoreleasePoolPush();
	OFStringEncoding encoding = [OFLocale encoding];
	OFArray OF_GENERIC(OFSandboxUnveilPath) *unveiledPaths;
	size_t unveiledPathsCount;
	const char *promises;

	if (_activeSandbox != nil && sandbox != _activeSandbox)
		@throw [OFInvalidArgumentException exception];

	unveiledPaths = sandbox.unveiledPaths;
	unveiledPathsCount = unveiledPaths.count;

	for (size_t i = sandbox->_unveiledPathsIndex;
	    i < unveiledPathsCount; i++) {
		OFSandboxUnveilPath unveiledPath =
		    [unveiledPaths objectAtIndex: i];
		OFString *path = unveiledPath.firstObject;
		OFString *permissions = unveiledPath.secondObject;

		if (path == nil || permissions == nil)
			@throw [OFInvalidArgumentException exception];

		unveil([path cStringWithEncoding: encoding],
		    [permissions cStringWithEncoding: encoding]);
	}

	sandbox->_unveiledPathsIndex = unveiledPathsCount;

	promises = [sandbox.pledgeString cStringWithEncoding: encoding];

	if (pledge(promises, NULL) != 0)
		@throw [OFActivateSandboxFailedException
		    exceptionWithSandbox: sandbox
				   errNo: errno];

	objc_autoreleasePoolPop(pool);

	if (_activeSandbox == nil)
		_activeSandbox = objc_retain(sandbox);
# endif
}

- (void)of_activateSandboxForChildProcesses: (OFSandbox *)sandbox
{
# ifdef OF_HAVE_PLEDGE
	void *pool = objc_autoreleasePoolPush();
	const char *promises;

	if (_activeSandboxForChildProcesses != nil &&
	    sandbox != _activeSandboxForChildProcesses)
		@throw [OFInvalidArgumentException exception];

	if (sandbox.unveiledPaths.count != 0)
		@throw [OFInvalidArgumentException exception];

	promises = [sandbox.pledgeString
	    cStringWithEncoding: [OFLocale encoding]];

	if (pledge(NULL, promises) != 0)
		@throw [OFActivateSandboxFailedException
		    exceptionWithSandbox: sandbox
				   errNo: errno];

	objc_autoreleasePoolPop(pool);

	if (_activeSandboxForChildProcesses == nil)
		_activeSandboxForChildProcesses = objc_retain(sandbox);
# endif
}
#endif
@end
