/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFSandbox;

/*!
 * @class OFSandboxActivationFailedException \
 *	  OFSandboxActivationFailedException.h \
 *	  ObjFW/OFSandboxActivationFailedException.h
 *
 * @brief An exception indicating that sandboxing the process failed.
 */
@interface OFSandboxActivationFailedException: OFException
{
	OFSandbox *_sandbox;
	int _errNo;
}

/*!
 * The sandbox which could not be activated.
 */
@property (readonly, nonatomic) OFSandbox *sandbox;

/*!
 * The errno of the error that occurred.
 */
@property (readonly) int errNo;

/*!
 * @brief Creates a new, autoreleased sandboxing failed exception.
 *
 * @param sandbox The sandbox which could not be activated
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased sandboxing failed exception
 */
+ (instancetype)exceptionWithSandbox: (OFSandbox *)sandbox
			       errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated sandboxing failed exception.
 *
 * @param sandbox The sandbox which could not be activated
 * @param errNo The errno of the error that occurred
 * @return An initialized sandboxing failed exception
 */
- initWithSandbox: (OFSandbox *)sandbox
	    errNo: (int)errNo;
@end

OF_ASSUME_NONNULL_END
