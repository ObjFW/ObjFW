/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#include <signal.h>

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFSandbox;
@class OFString;

#define OF_APPLICATION_DELEGATE(class_)					\
	int								\
	main(int argc, char *argv[])					\
	{								\
		return of_application_main(&argc, &argv,		\
		    (class_ *)[[class_ alloc] init]);			\
	}

#ifdef OF_HAVE_PLEDGE
# define OF_HAVE_SANDBOX
#endif

/*!
 * @protocol OFApplicationDelegate OFApplication.h ObjFW/OFApplication.h
 *
 * @brief A protocol for delegates of OFApplication.
 */
@protocol OFApplicationDelegate <OFObject>
/*!
 * @brief A method which is called when the application was initialized and is
 *	  running now.
 */
- (void)applicationDidFinishLaunching;

@optional
/*!
 * @brief A method which is called when the application will terminate.
 */
- (void)applicationWillTerminate;

/*!
 * @brief A method which is called when the application received a SIGINT.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 */
- (void)applicationDidReceiveSIGINT;

#ifdef SIGHUP
/*!
 * @brief A method which is called when the application received a SIGHUP.
 *
 * This signal is not available on Windows.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 */
- (void)applicationDidReceiveSIGHUP;
#endif

#ifdef SIGUSR1
/*!
 * @brief A method which is called when the application received a SIGUSR1.
 *
 * This signal is not available on Windows.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 */
- (void)applicationDidReceiveSIGUSR1;
#endif

#ifdef SIGUSR2
/*!
 * @brief A method which is called when the application received a SIGUSR2.
 *
 * This signal is not available on Windows.
 *
 * @warning You are not allowed to send any messages inside this method, as
 *	    message dispatching is not signal-safe! You are only allowed to do
 *	    signal-safe operations like setting a variable or calling a
 *	    signal-safe function!
 */
- (void)applicationDidReceiveSIGUSR2;
#endif
@end

/*!
 * @class OFApplication OFApplication.h ObjFW/OFApplication.h
 *
 * @brief A class which represents the application as an object.
 *
 * In order to create a new OFApplication, you should create a class conforming
 * to the optional @ref OFApplicationDelegate protocol and put
 * `OF_APPLICATION_DELEGATE(NameOfYourClass)` in the .m file of that class.
 */
@interface OFApplication: OFObject
{
	OFString *_programName;
	OFArray OF_GENERIC(OFString *) *_arguments;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *_environment;
	int *_argc;
	char ***_argv;
#ifdef OF_APPLICATION_M
@public
#endif
	id <OFApplicationDelegate> _Nullable _delegate;
	void (*_Nullable _SIGINTHandler)(id, SEL);
#ifndef OF_WINDOWS
	void (*_Nullable _SIGHUPHandler)(id, SEL);
	void (*_Nullable _SIGUSR1Handler)(id, SEL);
	void (*_Nullable _SIGUSR2Handler)(id, SEL);
#endif
#ifdef OF_HAVE_SANDBOX
	OFSandbox *_Nullable _activeSandbox, *_Nullable _activeExecSandbox;
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

/*!
 * @brief The name of the program (argv[0]).
 */
@property (readonly, nonatomic) OFString *programName;

/*!
 * @brief The arguments passed to the application.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *arguments;

/*!
 * @brief The environment of the application.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *environment;

/*!
 * @brief The delegate of the application.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFApplicationDelegate> delegate;

#ifdef OF_HAVE_SANDBOX
/*!
 * @brief The sandbox currently active for this application.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFSandbox *activeSandbox;

/*!
 * @brief The sandbox currently active for `exec()`'d processes of this
 *	  application.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFSandbox *activeExecSandbox;
#endif

/*!
 * @brief Returns the only OFApplication instance in the application.
 *
 * @return The only OFApplication instance in the application
 */
+ (nullable OFApplication *)sharedApplication;

/*!
 * @brief Returns the name of the program (argv[0]).
 *
 * @return The name of the program (argv[0])
 */
+ (nullable OFString *)programName;

/*!
 * @brief Returns the arguments passed to the application.
 *
 * @return The arguments passed to the application
 */
+ (nullable OFArray OF_GENERIC(OFString *) *)arguments;

/*!
 * @brief Returns the environment of the application.
 *
 * @return The environment of the application
 */
+ (nullable OFDictionary OF_GENERIC(OFString *, OFString *) *)environment;

/*!
 * @brief Terminates the application with the EXIT_SUCCESS status.
 */
+ (void)terminate OF_NO_RETURN;

/*!
 * @brief Terminates the application with the specified status.
 *
 * @param status The status with which the application will terminate
 */
+ (void)terminateWithStatus: (int)status OF_NO_RETURN;

#ifdef OF_HAVE_SANDBOX
/*!
 * @brief Activates the specified sandbox for the application.
 *
 * This is only available if `OF_HAVE_SANDBOX` is defined.
 *
 * @warning If you allow `exec()`, but do not call
 * @ref activateSandboxForExecdProcesses, an `exec()`'d process does not have
 * its permissions restricted!
 *
 * @note Once a sandbox has been activated, you cannot activate a different
 *	 sandbox. You can however change the active sandbox and reactivate it.
 *
 * @param sandbox The sandbox to activate
 */
+ (void)activateSandbox: (OFSandbox *)sandbox;

/*!
 * @brief Activates the specified sandbox for `exec()`'d processes of the
 *	  application.
 *
 * This is only available if `OF_HAVE_SANDBOX` is defined.
 *
 * `unveiledPaths` on the sandbox must *not* be empty, otherwise an
 * @ref OFInvalidArgumentException is raised.
 *
 * @note Once a sandbox has been activated, you cannot activate a different
 *	 sandbox. You can however change the active sandbox and reactivate it.
 *
 * @param sandbox The sandbox to activate
 */
+ (void)activateSandboxForExecdProcesses: (OFSandbox *)sandbox;
#endif

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Gets argc and argv.
 *
 * @param argc A pointer where a pointer to argc should be stored
 * @param argv A pointer where a pointer to argv should be stored
 */
- (void)getArgumentCount: (int *_Nonnull *_Nonnull)argc
       andArgumentValues: (char *_Nullable *_Nonnull *_Nonnull[_Nonnull])argv;

/*!
 * @brief Terminates the application.
 */
- (void)terminate OF_NO_RETURN;

/*!
 * @brief Terminates the application with the specified status.
 *
 * @param status The status with which the application will terminate
 */
- (void)terminateWithStatus: (int)status OF_NO_RETURN;

#ifdef OF_HAVE_SANDBOX
/*!
 * @brief Activates the specified sandbox for the application.
 *
 * This is only available if `OF_HAVE_SANDBOX` is defined.
 *
 * @warning If you allow `exec()`, but do not call
 * @ref activateSandboxForExecdProcesses, an `exec()`'d process does not have
 * its permissions restricted!
 *
 * @note Once a sandbox has been activated, you cannot activate a different
 *	 sandbox. You can however change the active sandbox and reactivate it.
 *
 * @param sandbox The sandbox to activate
 */
- (void)activateSandbox: (OFSandbox *)sandbox;

/*!
 * @brief Activates the specified sandbox for `exec()`'d processes of the
 *	  application.
 *
 * This is only available if `OF_HAVE_SANDBOX` is defined.
 *
 * `unveiledPaths` on the sandbox must *not* be empty, otherwise an
 * @ref OFInvalidArgumentException is raised.
 *
 * @note Once a sandbox has been activated, you cannot activate a different
 *	 sandbox. You can however change the active sandbox and reactivate it.
 *
 * @param sandbox The sandbox to activate
 */
- (void)activateSandboxForExecdProcesses: (OFSandbox *)sandbox;
#endif
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int of_application_main(int *_Nonnull,
    char *_Nullable *_Nonnull[_Nonnull], id <OFApplicationDelegate>);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
