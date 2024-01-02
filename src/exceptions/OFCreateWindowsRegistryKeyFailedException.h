/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFCreateWindowsRegistryKeyFailedException \
 *	  OFCreateWindowsRegistryKeyFailedException.h \
 *	  ObjFW/OFCreateWindowsRegistryKeyFailedException.h
 *
 * @brief An exception indicating that creating a Windows registry key failed.
 */
@interface OFCreateWindowsRegistryKeyFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_path;
	DWORD _options;
	REGSAM _accessRights;
	LPSECURITY_ATTRIBUTES _Nullable _securityAttributes;
	LSTATUS _status;
	OF_RESERVE_IVARS(OFCreateWindowsRegistryKeyFailedException, 4)
}

/**
 * @brief The registry key on which creating the subkey failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The path for the subkey that could not be created.
 */
@property (readonly, nonatomic) OFString *path;

/**
 * @brief The access rights for the subkey that could not be created.
 */
@property (readonly, nonatomic) REGSAM accessRights;

/**
 * @brief The security options for the subkey that could not be created.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    LPSECURITY_ATTRIBUTES securityAttributes;

/**
 * @brief The options for the subkey that could not be created.
 */
@property (readonly, nonatomic) DWORD options;

/**
 * @brief The status returned by RegCreateKeyEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/**
 * @brief Creates a new, autoreleased create Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which creating the subkey failed
 * @param path The path for the subkey that could not be created
 * @param accessRights The access rights for the sub key that could not be
 *		       created
 * @param securityAttributes The security options for the subkey that could
 *			     not be created
 * @param options The options for the subkey that could not be created
 * @param status The status returned by RegCreateKeyEx()
 * @return A new, autoreleased creates Windows registry key failed exception
 */
+ (instancetype)
    exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			path: (OFString *)path
		accessRights: (REGSAM)accessRights
	  securityAttributes: (nullable LPSECURITY_ATTRIBUTES)securityAttributes
		     options: (DWORD)options
		      status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated create Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which creating the subkey failed
 * @param path The path for the subkey that could not be created
 * @param accessRights The access rights for the sub key that could not be
 *		       created
 * @param securityAttributes The security options for the subkey that could
 *			     not be created
 * @param options The options for the subkey that could not be created
 * @param status The status returned by RegCreateKeyEx()
 * @return An initialized create Windows registry key failed exception
 */
- (instancetype)
	initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
		       path: (OFString *)path
	       accessRights: (REGSAM)accessRights
	 securityAttributes: (nullable LPSECURITY_ATTRIBUTES)securityAttributes
		    options: (DWORD)options
		     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
