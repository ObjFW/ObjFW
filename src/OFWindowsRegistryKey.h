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

#import "OFObject.h"
#import "OFString.h"

#include <windows.h>

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/*!
 * @class OFWindowsRegistryKey \
 *	  OFWindowsRegistryKey.h ObjFW/OFWindowsRegistryKey.h
 */
@interface OFWindowsRegistryKey: OFObject
{
	HKEY _hKey;
	bool _close;
}

/*!
 * @brief Returns the OFWindowsRegistryKey for the HKEY_CLASSES_ROOT key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_CLASSES_ROOT key
 */
+ (instancetype)classesRootKey;

/*!
 * @brief Returns the OFWindowsRegistryKey for the HKEY_CURRENT_CONFIG key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_CURRENT_CONFIG key
 */
+ (instancetype)currentConfigKey;

/*!
 * @brief Returns the OFWindowsRegistryKey for the HKEY_CURRENT_USER key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_CURRENT_USER key
 */
+ (instancetype)currentUserKey;

/*!
 * @brief Returns the OFWindowsRegistryKey for the HKEY_LOCAL_MACHINE key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_LOCAL_MACHINE key
 */
+ (instancetype)localMachineKey;

/*!
 * @brief Returns the OFWindowsRegistryKey for the HKEY_USERS key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_USERS key
 */
+ (instancetype)usersKey;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Opens the subkey at the specified path.
 *
 * @param path The path of the subkey to open
 * @param securityAndAccessRights Please refer to the `RegOpenKeyEx()`
 *				  documentation
 * @return The subkey with the specified path, or nil if it does not exist
 */
- (nullable OFWindowsRegistryKey *)
	 openSubKeyWithPath: (OFString *)path
    securityAndAccessRights: (REGSAM)securityAndAccessRights;

/*!
 * @brief Opens the subkey at the specified path.
 *
 * @param path The path of the subkey to open
 * @param options Please refer to the `RegOpenKeyEx()` documentation. Usually 0.
 * @param securityAndAccessRights Please refer to the `RegOpenKeyEx()`
 *				  documentation
 * @return The subkey with the specified path, or nil if it does not exist
 */
- (nullable OFWindowsRegistryKey *)
	 openSubKeyWithPath: (OFString *)path
		    options: (DWORD)options
    securityAndAccessRights: (REGSAM)securityAndAccessRights;

/*!
 * @brief Creates a subkey at the specified path or opens it if it already
 *	  exists.
 *
 * @param path The path of the subkey to create
 * @param securityAndAccessRights Please refer to the `RegCreateKeyEx()`
 *				  documentation
 * @return The subkey with the specified path
 */
- (OFWindowsRegistryKey *)
       createSubKeyWithPath: (OFString *)path
    securityAndAccessRights: (REGSAM)securityAndAccessRights;

/*!
 * @brief Creates a subkey at the specified path or opens it if it already
 *	  exists.
 *
 * @param path The path of the subkey to create
 * @param options Please refer to the `RegCreateKeyEx()` documentation.
 *		  Usually 0.
 * @param securityAndAccessRights Please refer to the `RegCreateKeyEx()`
 *				  documentation
 * @param securityAttributes Please refer to the `RegCreateKeyEx()`
 *			     documentation. Usually NULL.
 * @param disposition Whether the key was created or already existed. Please
 *		      refer to the `RegCreateKeyEx()` documentation.
 * @return The subkey with the specified path
 */
- (OFWindowsRegistryKey *)
       createSubKeyWithPath: (OFString *)path
		    options: (DWORD)options
    securityAndAccessRights: (REGSAM)securityAndAccessRights
	 securityAttributes: (nullable LPSECURITY_ATTRIBUTES)securityAttributes
		disposition: (nullable LPDWORD)disposition;

/*!
 * @brief Returns the string for the specified value at the specified path.
 *
 * @param value The name of the value to return
 * @param subkeyPath The path of the key from which to retrieve the value
 * @return The string for the specified value
 */
- (nullable OFString *)stringForValue: (nullable OFString *)value
			   subkeyPath: (nullable OFString *)subkeyPath;

/*!
 * @brief Returns the data for the specified value at the specified path.
 *
 * @param value The name of the value to return
 * @param subkeyPath The path of the key from which to retrieve the value
 * @param flags Extra flags for `RegGetValue()`. Usually 0.
 * @param type A pointer to store the type of the value, or NULL
 * @return The data for the specified value
 */
- (nullable OFData *)dataForValue: (nullable OFString *)value
		       subkeyPath: (nullable OFString *)subkeyPath
			    flags: (DWORD)flags
			     type: (nullable LPDWORD)type;
@end

OF_ASSUME_NONNULL_END
