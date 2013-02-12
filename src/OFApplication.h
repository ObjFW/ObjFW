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

#import "OFObject.h"

@class OFString;
@class OFArray;
@class OFDictionary;
@class OFMutableArray;
@class OFMutableDictionary;

#define OF_APPLICATION_DELEGATE(cls)					\
	int								\
	main(int argc, char *argv[])					\
	{								\
		return of_application_main(&argc, &argv, [cls class]);	\
	}

/*!
 * @brief A protocol for delegates of OFApplication.
 */
@protocol OFApplicationDelegate <OFObject>
/*!
 * @brief A method which is called when the application was initialized and is
 *	  running now.
 */
- (void)applicationDidFinishLaunching;

#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
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

#ifndef _WIN32
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
 * @brief Represents the application as an object.
 */
@interface OFApplication: OFObject
{
	OFString *_programName;
	OFArray *_arguments;
	OFDictionary *_environment;
	int *_argc;
	char ***_argv;
@public
	id <OFApplicationDelegate> _delegate;
	void (*_SIGINTHandler)(id, SEL);
#ifndef _WIN32
	void (*_SIGHUPHandler)(id, SEL);
	void (*_SIGUSR1Handler)(id, SEL);
	void (*_SIGUSR2Handler)(id, SEL);
#endif
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy, nonatomic) OFString *programName;
@property (readonly, copy, nonatomic) OFArray *arguments;
@property (readonly, copy, nonatomic) OFDictionary *environment;
@property (assign) id <OFApplicationDelegate> delegate;
#endif

/*!
 * @brief Returns the only OFApplication instance in the application.
 *
 * @return The only OFApplication instance in the application
 */
+ (OFApplication*)sharedApplication;

/*!
 * @brief Returns the name of the program (argv[0]).
 *
 * @return The name of the program (argv[0])
 */
+ (OFString*)programName;

/*!
 * @brief Returns the arguments passed to the application.
 *
 * @return The arguments passed to the application
 */
+ (OFArray*)arguments;

/*!
 * @brief Returns the environment of the application.
 *
 * @return The environment of the application
 */
+ (OFDictionary*)environment;

/*!
 * @brief Terminates the application.
 */
+ (void)terminate;

/*!
 * @brief Terminates the application with the specified status.
 *
 * @param status The status with which the application will terminate
 */
+ (void)terminateWithStatus: (int)status;

- (void)OF_setArgumentCount: (int*)argc
	  andArgumentValues: (char**[])argv;
#ifdef _WIN32
- (void)OF_setArgumentCount: (int)argc
      andWideArgumentValues: (wchar_t*[])argv;
#endif

/*!
 * @brief Gets args and argv.
 *
 * @param argc A pointer where a pointer to argc should be stored
 * @param argv A pointer where a pointer to argv should be stored
 */
- (void)getArgumentCount: (int**)argc
       andArgumentValues: (char***[])argv;

/*!
 * @brief Returns the name of the program (argv[0]).
 *
 * @return The name of the program (argv[0])
 */
- (OFString*)programName;

/*!
 * @brief Returns the arguments passed to the application.
 *
 * @return The arguments passed to the application
 */
- (OFArray*)arguments;

/*!
 * @brief Returns the environment of the application.
 *
 * @return The environment of the application
 */
- (OFDictionary*)environment;

/*!
 * @brief Returns the delegate of the application.
 *
 * @return The delegate of the application
 */
- (id <OFApplicationDelegate>)delegate;

/*!
 * @brief Sets the delegate of the application.
 *
 * @param delegate The delegate for the application
 */
- (void)setDelegate: (id <OFApplicationDelegate>)delegate;

/*!
 * @brief Starts the application after everything has been initialized.
 *
 * You should not call this directly, but use OF_APPLICATION_DELEGATE instead!
 */
- (void)run;

/*!
 * @brief Terminates the application.
 */
- (void)terminate;

/*!
 * @brief Terminates the application with the specified status.
 *
 * @param status The status with which the application will terminate
 */
- (void)terminateWithStatus: (int)status;
@end

@interface OFObject (OFApplicationDelegate) <OFApplicationDelegate>
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int of_application_main(int*, char**[], Class);
#ifdef __cplusplus
}
#endif
