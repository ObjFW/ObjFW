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

@class OFArray;
@class OFMutableArray;

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
	OFMutableArray *arguments;
	id delegate;
}

/**
 * \return The only OFApplication instance in the application
 */
+ sharedApplication;

/**
 * \return The arguments passed to the application
 */
+ (OFArray*)arguments;

/**
 * Terminates the application.
 */
+ (void)terminate;

/**
 * Sets argc and argv.
 *
 * You should not call this directly! Use of_application_main instead!
 *
 * \param argc The number of arguments
 * \param argv The argument values
 */
-  setArgumentCount: (int)argc
  andArgumentValues: (char**)argv;

/**
 * \return The arguments passed to the application
 */
- (OFArray*)arguments;

/**
 * \return The delegate of the application
 */
- (id)delegate;

/**
 * Sets the delegate of the application.
 *
 * \param delegate The delegate for the application
 */
- setDelegate: (id)delegate;

/**
 * Starts the application after everything has been initialized.
 */
- run;

/**
 * Terminates the application.
 */
- (void)terminate;
@end

@interface OFObject (OFApplicationDelegate) <OFApplicationDelegate>
@end

extern int of_application_main(int, char*[], Class);
