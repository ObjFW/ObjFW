/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
 * @class OFOpenWindowsRegistryKeyFailedException \
 *	  OFOpenWindowsRegistryKeyFailedException.h \
 *	  ObjFW/OFOpenWindowsRegistryKeyFailedException.h
 *
 * @brief An exception indicating that opening a Windows registry key failed.
 */
@interface OFOpenWindowsRegistryKeyFailedException: OFException
{
	OFWindowsRegistryKey *_registryKey;
	OFString *_path;
	REGSAM _accessRights;
	LPSECURITY_ATTRIBUTES _Nullable _securityAttributes;
	DWORD _options;
	LSTATUS _status;
	OF_RESERVE_IVARS(OFOpenWindowsRegistryKeyFailedException, 4)
}

/**
 * @brief The registry key on which opening the subkey failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/**
 * @brief The path for the subkey that could not be opened.
 */
@property (readonly, nonatomic) OFString *path;

/**
 * @brief The access rights for the subkey that could not be opened.
 */
@property (readonly, nonatomic) REGSAM accessRights;

/**
 * @brief The options for the subkey that could not be opened.
 */
@property (readonly, nonatomic) DWORD options;

/**
 * @brief The status returned by RegOpenKeyEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/**
 * @brief Creates a new, autoreleased open Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which opening the subkey failed
 * @param path The path for the subkey that could not be opened
 * @param accessRights The access rights for the sub key that could not be
 *		       opened
 * @param options The options for the subkey that could not be opened
 * @param status The status returned by RegOpenKeyEx()
 * @return A new, autoreleased open Windows registry key failed exception
 */
+ (instancetype)exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
				    path: (OFString *)path
			    accessRights: (REGSAM)accessRights
				 options: (DWORD)options
				  status: (LSTATUS)status;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated open Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which opening the subkey failed
 * @param path The path for the subkey that could not be opened
 * @param accessRights The access rights for the sub key that could not be
 *		       opened
 * @param options The options for the subkey that could not be opened
 * @param status The status returned by RegOpenKeyEx()
 * @return An initialized open Windows registry key failed exception
 */
- (instancetype)initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			       path: (OFString *)path
		       accessRights: (REGSAM)accessRights
			    options: (DWORD)options
			     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
