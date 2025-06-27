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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFSandbox;

/**
 * @class OFSandboxActivationFailedException \
 *	  OFSandboxActivationFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that sandboxing the process failed.
 */
@interface OFSandboxActivationFailedException: OFException
{
	OFSandbox *_sandbox;
	int _errNo;
}

/**
 * @brief The sandbox which could not be activated.
 */
@property (readonly, nonatomic) OFSandbox *sandbox;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased sandboxing failed exception.
 *
 * @param sandbox The sandbox which could not be activated
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased sandboxing failed exception
 */
+ (instancetype)exceptionWithSandbox: (OFSandbox *)sandbox errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated sandboxing failed exception.
 *
 * @param sandbox The sandbox which could not be activated
 * @param errNo The errno of the error that occurred
 * @return An initialized sandboxing failed exception
 */
- (instancetype)initWithSandbox: (OFSandbox *)sandbox
			  errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
