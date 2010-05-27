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
		return of_application_main(argc, argv, [cls class]);	\
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
	id delegate;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) OFString *programName;
@property (readonly, retain) OFArray *arguments;
@property (readonly, retain) OFDictionary *environment;
@property (retain) id delegate;
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
- (void)setArgumentCount: (int)argc
       andArgumentValues: (char**)argv;

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
- (id)delegate;

/**
 * Sets the delegate of the application.
 *
 * \param delegate The delegate for the application
 */
- (void)setDelegate: (id)delegate;

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

extern int of_application_main(int, char*[], Class);
