/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#import "OFWindowsRegistryKey.h"

#include <windows.h>

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFSetWindowsRegistryValueFailedException \
 *	  OFSetWindowsRegistryValueFailedException.h \
 *	  ObjFW/OFSetWindowsRegistryValueFailedException.h
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
