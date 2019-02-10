/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFWindowsRegistryKey.h"

#include <windows.h>

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFReadWindowsRegistryValueFailedException \
 *	  OFReadWindowsRegistryValueFailedException.h \
 *	  ObjFW/OFReadWindowsRegistryValueFailedException.h
 *
 * @brief An exception indicating that reading a Windows registry value failed.
 */
@interface OFReadWindowsRegistryValueFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_Nullable _value, *_Nullable _subkeyPath;
	DWORD _flags;
	LSTATUS _status;
}

/*!
 * @brief The registry key on which reading the value at the key path failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/*!
 * @brief The value for which reading failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *value;

/*!
 * @brief The subkey path at which reading the value failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *subkeyPath;

/*!
 * @brief The flags with which reading the value failed.
 */
@property (readonly, nonatomic) DWORD flags;

/*!
 * @brief The status returned by RegGetValueEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/*!
 * @brief Creates a new, autoreleased read Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which reading the value at the sub
 *		      key path failed
 * @param value The value for which reading failed
 * @param subkeyPath The subkey path at which reading the value failed
 * @param flags The flags with which reading the value failed
 * @param status The status returned by RegGetValueEx()
 * @return A new, autoreleased read Windows registry value failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				   value: (nullable OFString *)value
			      subkeyPath: (nullable OFString *)subkeyPath
				   flags: (DWORD)flags
				  status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated read Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which reading the value at the sub
 *		      key path failed
 * @param value The value for which reading failed
 * @param subkeyPath The subkey path at which reading the value failed
 * @param flags The flags with which reading the value failed
 * @param status The status returned by RegGetValueEx()
 * @return An initialized read Windows registry value failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      value: (nullable OFString *)value
			 subkeyPath: (nullable OFString *)subkeyPath
			      flags: (DWORD)flags
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
