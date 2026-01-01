/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <signal.h>

#import "OFObject.h"
#import "OFNotification.h"

#ifdef OF_WINDOWS
# include <windows.h>
#endif

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFSandbox;
@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief A notification that will be sent when the application did finish
 *	  launching.
 */
extern const OFNotificationName OFApplicationDidFinishLaunchingNotification;

/**
 * @brief A notification that will be sent when the application will terminate.
 */
extern const OFNotificationName OFApplicationWillTerminateNotification;
#ifdef __cplusplus
}
#endif

/**
 * @brief Specify the class to be used as the application delegate.
 *
 * An instance of this class will be created and act as the application
 * delegate.
 *
 * For example, it can be used like this:
 *
 * @code
 * // In MyAppDelegate.h:
 * @interface MyAppDelegate: OFObject <OFApplicationDelegate>
 * @end
 *
 * // In MyAppDelegate.m:
 * OF_APPLICATION_DELEGATE(MyAppDelegate)
 *
 * @implementation MyAppDelegate
 * - (void)applicationDidFinishLaunching: (OFNotification *)notification
 * {
 *         [OFApplication terminate];
 * }
 * @end
 * @endcode
 */
#ifndef OF_WINDOWS
# define OF_APPLICATION_DELEGATE(class_)		\
	int						\
	main(int argc, char *argv[])			\
	{						\
		return OFApplicationMain(&argc, &argv,	\
		    (class_ *)[[class_ alloc] init]);	\
	}
#else
# define OF_APPLICATION_DELEGATE(class_)				\
	int								\
	main(int argc, char *argv[])					\
	{								\
		return OFApplicationMain(&argc, &argv,			\
		    (class_ *)[[class_ alloc] init]);			\
	}								\
									\
	WINAPI int							\
	WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,		\
	    LPSTR lpCmdLine, int nShowCmd)				\
	{								\
		int argc = 0, si = 0;					\
		char **argv = NULL, **envp = NULL;			\
									\
		__getmainargs(&argc, &argv, &envp, _CRT_glob, &si);	\
									\
		return OFApplicationMain(&argc, &argv,			\
		    (class_ *)[[class_ alloc] init]);			\
	}
# ifdef __cplusplus
extern "C" {
# endif
extern void __getmainargs(int *_Nonnull, char *_Nonnull *_Nullable *_Nullable,
    char *_Nonnull *_Nullable *_Nullable, int, int *_Nonnull);
extern int _CRT_glob;
# ifdef __cplusplus
}
# endif
#endif

#ifdef OF_HAVE_PLEDGE
# define OF_HAVE_SANDBOX
#endif

/**
 * @protocol OFApplicationDelegate OFApplication.h ObjFW/ObjFW.h
 *
 * @brief A protocol for delegates of OFApplication.
 *
 * @note Signals are not available on AmigaOS!
 */
@protocol OFApplicationDelegate <OFObject>
/**
 * @brief A method which is called when the application was initialized and is
 *	  running now.
 *
 * @param notification A notification with name
 *		       OFApplicationDidFinishLaunchingNotification
 */
- (void)applicationDidFinishLaunching: (OFNotification *)notification;

@optional
/**
 * @brief A method which is called when the application will terminate.
 *
 * @param notification A notification with name
 *		       OFApplicationWillTerminateNotification
 */
- (void)applicationWillTerminate: (OFNotification *)notification;

#ifndef OF_AMIGAOS
/**
 * @brief A method which is called when the application received a SIGINT.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 *
 * @note This method is not available on AmigaOS.
 */
- (void)applicationDidReceiveSIGINT;

# ifdef SIGHUP
/**
 * @brief A method which is called when the application received a SIGHUP.
 *
 * This signal is not available on Windows.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 *
 * @note This method is not available on AmigaOS.
 */
- (void)applicationDidReceiveSIGHUP;
# endif

# ifdef SIGUSR1
/**
 * @brief A method which is called when the application received a SIGUSR1.
 *
 * This signal is not available on Windows.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 *
 * @note This method is not available on AmigaOS.
 */
- (void)applicationDidReceiveSIGUSR1;
# endif

# ifdef SIGUSR2
/**
 * @brief A method which is called when the application received a SIGUSR2.
 *
 * This signal is not available on Windows.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 *
 * @note This method is not available on AmigaOS.
 */
- (void)applicationDidReceiveSIGUSR2;
# endif
#endif
@end

/**
 * @class OFApplication OFApplication.h ObjFW/ObjFW.h
 *
 * @brief A class which represents the application as an object.
 *
 * In order to create a new OFApplication, you should create a class conforming
 * to the optional @ref OFApplicationDelegate protocol and put
 * `OF_APPLICATION_DELEGATE(NameOfYourClass)` in the .m file of that class.
 *
 * When the application is about to be terminated,
 * @ref OFApplicationDelegate#applicationWillTerminate: will be called on the
 * delegate and an @ref OFApplicationWillTerminateNotification will be sent.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFApplication: OFObject
{
	OFString *_programName;
	OFArray OF_GENERIC(OFString *) *_arguments;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *_environment;
	int *_argc;
	char ***_argv;
	id <OFApplicationDelegate> _Nullable _delegate;
	void (*_Nullable _SIGINTHandler)(id, SEL);
#ifndef OF_WINDOWS
	void (*_Nullable _SIGHUPHandler)(id, SEL);
	void (*_Nullable _SIGUSR1Handler)(id, SEL);
	void (*_Nullable _SIGUSR2Handler)(id, SEL);
#endif
#ifdef OF_HAVE_SANDBOX
	OFSandbox *_Nullable _activeSandbox;
	OFSandbox *_Nullable _activeSandboxForChildProcesses;
#endif
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nullable, nonatomic)
    OFApplication *sharedApplication;
@property (class, readonly, nullable, nonatomic) OFString *programName;
@property (class, readonly, nullable, nonatomic)
    OFArray OF_GENERIC(OFString *) *arguments;
@property (class, readonly, nullable, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *environment;
#endif

/**
 * @brief The name of the program (argv[0]).
 */
@property (readonly, nonatomic) OFString *programName;

/**
 * @brief The arguments passed to the application.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *arguments;

/**
 * @brief The environment of the application.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *environment;

/**
 * @brief The delegate of the application.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFApplicationDelegate> delegate;

#ifdef OF_HAVE_SANDBOX
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFSandbox *activeSandbox;
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFSandbox *activeSandboxForChildProcesses;
#endif

/**
 * @brief Returns the only OFApplication instance in the application.
 *
 * @return The only OFApplication instance in the application
 */
+ (nullable OFApplication *)sharedApplication;

/**
 * @brief Returns the name of the program (argv[0]).
 *
 * @return The name of the program (argv[0])
 */
+ (nullable OFString *)programName;

/**
 * @brief Returns the arguments passed to the application.
 *
 * @return The arguments passed to the application
 */
+ (nullable OFArray OF_GENERIC(OFString *) *)arguments;

/**
 * @brief Returns the environment of the application.
 *
 * @return The environment of the application
 */
+ (nullable OFDictionary OF_GENERIC(OFString *, OFString *) *)environment;

/**
 * @brief Terminates the application with the EXIT_SUCCESS status.
 */
+ (void)terminate OF_NO_RETURN;

/**
 * @brief Terminates the application with the specified status.
 *
 * @param status The status with which the application will terminate
 */
+ (void)terminateWithStatus: (int)status OF_NO_RETURN;

#ifdef OF_HAVE_SANDBOX
+ (void)of_activateSandbox: (OFSandbox *)sandbox;
+ (void)of_activateSandboxForChildProcesses: (OFSandbox *)sandbox;
#endif

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Gets argc and argv.
 *
 * @param argc A pointer where a pointer to argc should be stored
 * @param argv A pointer where a pointer to argv should be stored
 */
- (void)getArgumentCount: (int *_Nonnull *_Nonnull)argc
       andArgumentValues: (char *_Nullable *_Nonnull *_Nonnull[_Nonnull])argv;

/**
 * @brief Terminates the application.
 */
- (void)terminate OF_NO_RETURN;

/**
 * @brief Terminates the application with the specified status.
 *
 * @param status The status with which the application will terminate
 */
- (void)terminateWithStatus: (int)status OF_NO_RETURN;

#ifdef OF_HAVE_SANDBOX
- (void)of_activateSandbox: (OFSandbox *)sandbox;
- (void)of_activateSandboxForChildProcesses: (OFSandbox *)sandbox;
#endif
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int OFApplicationMain(int *_Nonnull, char *_Nullable *_Nonnull[_Nonnull],
    id <OFApplicationDelegate>);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
