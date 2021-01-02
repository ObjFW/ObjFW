/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
 * @class OFGetWindowsRegistryValueFailedException \
 *	  OFGetWindowsRegistryValueFailedException.h \
 *	  ObjFW/OFGetWindowsRegistryValueFailedException.h
 *
 * @brief An exception indicating that getting a Windows registry value failed.
 */
@interface OFGetWindowsRegistryValueFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_Nullable _value;
	DWORD _flags;
	LSTATUS _status;
}

/**
 * @brief The registry key on which getting the value at the key path failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The value which could not be retrieved.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *value;

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
 * @param value The value which could not be retrieved
 * @param status The status returned by RegGetValueEx()
 * @return A new, autoreleased get Windows registry value failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				   value: (nullable OFString *)value
				  status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated get Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which getting the value at the sub
 *		      key path failed
 * @param value The value which could not be retrieved
 * @param status The status returned by RegGetValueEx()
 * @return An initialized get Windows registry value failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      value: (nullable OFString *)value
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
