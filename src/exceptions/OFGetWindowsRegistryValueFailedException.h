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
 * @class OFGetWindowsRegistryValueFailedException
 *	  OFGetWindowsRegistryValueFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that getting a Windows registry value failed.
 */
@interface OFGetWindowsRegistryValueFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_Nullable _valueName;
	LSTATUS _status;
	OF_RESERVE_IVARS(OFGetWindowsRegistryValueFailedException, 4)
}

/**
 * @brief The registry key on which getting the value at the key path failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The name of the value which could not be retrieved.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *valueName;

/**
 * @brief The status returned by RegGetValueEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/**
 * @brief Creates a new, autoreleased get Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which getting the value at the sub
 *		      key path failed
 * @param valueName The name of the value which could not be retrieved
 * @param status The status returned by RegGetValueEx()
 * @return A new, autoreleased get Windows registry value failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       valueName: (nullable OFString *)valueName
				  status: (LSTATUS)status;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated get Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which getting the value at the sub
 *		      key path failed
 * @param valueName The name of the value which could not be retrieved
 * @param status The status returned by RegGetValueEx()
 * @return An initialized get Windows registry value failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			  valueName: (nullable OFString *)valueName
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
