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
 * @class OFDeleteWindowsRegistryValueFailedException \
 *	  OFDeleteWindowsRegistryValueFailedException.h \
 *	  ObjFW/OFDeleteWindowsRegistryValueFailedException.h
 *
 * @brief An exception indicating that deleting a Windows registry value failed.
 */
@interface OFDeleteWindowsRegistryValueFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_Nullable _value;
	LSTATUS _status;
}

/*!
 * @brief The registry key on which deleting the value failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/*!
 * @brief The value which could not be deleted.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *value;

/*!
 * @brief The status returned by RegDeleteValueEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/*!
 * @brief Creates a new, autoreleased delete Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which deleting the value failed
 * @param value The value which could not be deleted
 * @param status The status returned by RegDeleteValueEx()
 * @return A new, autoreleased delete Windows registry value failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				   value: (nullable OFString *)value
				  status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated delete Windows registry value failed
 *	  exception.
 *
 * @param registryKey The registry key on which deleting the value failed
 * @param value The value which could not be deleted
 * @param status The status returned by RegDeleteValueEx()
 * @return An initialized delete Windows registry value failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			      value: (nullable OFString *)value
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
