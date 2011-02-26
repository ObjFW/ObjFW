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

/**
 * \brief A protocol for delegates of OFApplication.
 */
@protocol OFApplicationDelegate
/**
 * This method is called when the application was initialized and is running
 * now.
 */
- (void)applicationDidFinishLaunching;

/**
 * This method is called when the application will terminate.
 */
- (void)applicationWillTerminate;
@end

/**
 * \brief Represents the application as an object.
 */
@interface OFApplication: OFObject
{
	OFString *programName;
	OFMutableArray *arguments;
	OFMutableDictionary *environment;
	id <OFApplicationDelegate> delegate;
	int *argc;
	char ***argv;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *programName;
@property (readonly, copy) OFArray *arguments;
@property (readonly, copy) OFDictionary *environment;
@property (retain) id <OFApplicationDelegate> delegate;
#endif

/**
 * \return The only OFApplication instance in the application
 */
+ sharedApplication;

/**
 * \return The name of the program (argv[0])
 */
+ (OFString*)programName;

/**
 * \return The arguments passed to the application
 */
+ (OFArray*)arguments;

/**
 * \return The environment of the application
 */
+ (OFDictionary*)environment;

/**
 * Terminates the application.
 */
+ (void)terminate;

/**
 * Terminates the application with the specified status.
 *
 * \param status The status with which the application will terminate
 */
+ (void)terminateWithStatus: (int)status;

/**
 * Sets argc and argv.
 *
 * You should not call this directly! Use of_application_main instead!
 *
 * \param argc The number of arguments
 * \param argv The argument values
 */
- (void)setArgumentCount: (int*)argc
       andArgumentValues: (char**[])argv;

/**
 * Gets args and argv.o
 *
 * \param argc A pointer where a pointer to argc should be stored
 * \param argv A pointer where a pointer to argv should be stored
 */
- (void)getArgumentCount: (int**)argc
       andArgumentValues: (char***[])argv;

/**
 * \return The name of the program (argv[0])
 */
- (OFString*)programName;

/**
 * \return The arguments passed to the application
 */
- (OFArray*)arguments;

/**
 * \return The environment of the application
 */
- (OFDictionary*)environment;

/**
 * \return The delegate of the application
 */
- (id <OFApplicationDelegate>)delegate;

/**
 * Sets the delegate of the application.
 *
 * \param delegate The delegate for the application
 */
- (void)setDelegate: (id <OFApplicationDelegate>)delegate;

/**
 * Starts the application after everything has been initialized.
 */
- (void)run;

/**
 * Terminates the application.
 */
- (void)terminate;

/**
 * Terminates the application with the specified status.
 *
 * \param status The status with which the application will terminate
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
