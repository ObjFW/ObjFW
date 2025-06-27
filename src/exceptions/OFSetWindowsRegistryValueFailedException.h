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
#import "OFWindowsRegistryKey.h"

#include <windows.h>

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFSetWindowsRegistryValueFailedException
 *	  OFSetWindowsRegistryValueFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that setting a Windows registry value failed.
 */
@interface OFSetWindowsRegistryValueFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_Nullable _valueName;
	OFData *_Nullable _data;
	DWORD _type;
	LSTATUS _status;
	OF_RESERVE_IVARS(OFSetWindowsRegistryValueFailedException, 4)
}

/**
 * @brief The registry key on which setting the value failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The name of the value which could not be set.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *valueName;

/**
 * @brief The data to which the value could not be set.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFData *data;

/**
 * @brief The type for the value that could not be set.
 */
@property (readonly, nonatomic) DWORD type;

/**
 * @brief The status returned by RegSetValueEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/**
 * @brief Creates a new, autoreleased set Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which setting the value failed
 * @param valueName The name of the value which could not be set
 * @param data The data to which the value could not be set
 * @param type The type for the value that could not be set
 * @param status The status returned by RegSetValueEx()
 * @return A new, autoreleased set Windows registry value failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       valueName: (nullable OFString *)valueName
				    data: (nullable OFData *)data
				    type: (DWORD)type
				  status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated set Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which setting the value failed
 * @param valueName The name of the value which could not be set
 * @param data The data to which the value could not be set
 * @param type The type for the value that could not be set
 * @param status The status returned by RegSetValueEx()
 * @return An initialized set Windows registry value failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			  valueName: (nullable OFString *)valueName
			       data: (nullable OFData *)data
			       type: (DWORD)type
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
