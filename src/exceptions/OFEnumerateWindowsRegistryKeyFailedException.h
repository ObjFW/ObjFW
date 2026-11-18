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

#import "OFException.h"
#import "OFWindowsRegistryKey.h"

#include <windows.h>

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFEnumerateWindowsRegistryKeyFailedException
 *	  OFEnumerateWindowsRegistryKeyFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that enumerating a Windows registry key
 *	  failed.
 */
@interface OFEnumerateWindowsRegistryKeyFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	LSTATUS _status;
	OF_RESERVE_IVARS(OFEnumerateWindowsRegistryKeyFailedException, 4)
}

/**
 * @brief The registry key on which enumeration failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The status returned during enumeration
 */
@property (readonly, nonatomic) LSTATUS status;

/**
 * @brief Creates a new, autoreleased enumerate Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which enumeration failed
 * @param status The status returned during enumeration
 * @return A new, autoreleased enumerate Windows registry key failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				  status: (LSTATUS)status;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated enumerate Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which enumeration failed
 * @param status The status returned during enumeration
 * @return An initialized enumerate Windows registry key failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
