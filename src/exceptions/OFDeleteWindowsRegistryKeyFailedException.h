/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFDeleteWindowsRegistryKeyFailedException
 *	  OFDeleteWindowsRegistryKeyFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that deleting a Windows registry key failed.
 */
@interface OFDeleteWindowsRegistryKeyFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_subkeyPath;
	LSTATUS _status;
	OF_RESERVE_IVARS(OFDeleteWindowsRegistryKeyFailedException, 4)
}

/**
 * @brief The registry key on which deleting the subkey failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The path of the subkey which could not be deleted.
 */
@property (readonly, nonatomic) OFString *subkeyPath;

/**
 * @brief The status returned by RegDeleteKeyEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/**
 * @brief Creates a new, autoreleased delete Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which deleting the subkey failed
 * @param subkeyPath The path of the subkey which could not be deleted
 * @param status The status returned by RegDeleteKeyEx()
 * @return A new, autoreleased delete Windows registry key failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      subkeyPath: (OFString *)subkeyPath
				  status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated delete Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which deleting the subkey failed
 * @param subkeyPath The path of the subkey which could not be deleted
 * @param status The status returned by RegDeleteKeyEx()
 * @return An initialized delete Windows registry key failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			 subkeyPath: (OFString *)subkeyPath
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
