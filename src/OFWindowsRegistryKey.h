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

#import "OFObject.h"
#import "OFString.h"

#include <windows.h>

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @class OFWindowsRegistryKey \
 *	  OFWindowsRegistryKey.h ObjFW/OFWindowsRegistryKey.h
 */
OF_SUBCLASSING_RESTRICTED
@interface OFWindowsRegistryKey: OFObject
{
	HKEY _hKey;
	bool _close;
}

/**
 * @brief Returns the OFWindowsRegistryKey for the HKEY_CLASSES_ROOT key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_CLASSES_ROOT key
 */
+ (instancetype)classesRootKey;

/**
 * @brief Returns the OFWindowsRegistryKey for the HKEY_CURRENT_CONFIG key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_CURRENT_CONFIG key
 */
+ (instancetype)currentConfigKey;

/**
 * @brief Returns the OFWindowsRegistryKey for the HKEY_CURRENT_USER key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_CURRENT_USER key
 */
+ (instancetype)currentUserKey;

/**
 * @brief Returns the OFWindowsRegistryKey for the HKEY_LOCAL_MACHINE key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_LOCAL_MACHINE key
 */
+ (instancetype)localMachineKey;

/**
 * @brief Returns the OFWindowsRegistryKey for the HKEY_USERS key.
 *
 * @return The OFWindowsRegistryKey for the HKEY_USERS key
 */
+ (instancetype)usersKey;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Opens the subkey at the specified path.
 *
 * @param path The path of the subkey to open
 * @param accessRights Please refer to the `RegOpenKeyEx()` documentation for
 *		       `samDesired`
 * @param options Please refer to the `RegOpenKeyEx()` documentation for
 *		  `ulOptions`. Usually 0.
 * @return The subkey with the specified path
 */
- (OFWindowsRegistryKey *)openSubkeyAtPath: (OFString *)path
			      accessRights: (REGSAM)accessRights
				   options: (DWORD)options;
/**
 * @brief Creates a subkey at the specified path or opens it if it already
 *	  exists.
 *
 * @param path The path of the subkey to create
 * @param accessRights Please refer to the `RegCreateKeyEx()` documentation for
 *		       `samDesired`
 * @param securityAttributes Please refer to the `RegCreateKeyEx()`
 *			     documentation for `lpSecurityAttributes`. Usually
 *			     NULL.
 * @param options Please refer to the `RegCreateKeyEx()` documentation for
 *		  `dwOptions`. Usually 0.
 * @param disposition A pointer to a variable that will be set to whether the
 *		      key was created or already existed, or `NULL`. Please
 *		      refer to the `RegCreateKeyEx()` documentation for
 *		      `lpdwDisposition`.
 * @return The subkey with the specified path
 */
- (OFWindowsRegistryKey *)
    createSubkeyAtPath: (OFString *)path
	  accessRights: (REGSAM)accessRights
    securityAttributes: (nullable SECURITY_ATTRIBUTES *)securityAttributes
	       options: (DWORD)options
	   disposition: (nullable DWORD *)disposition;

/**
 * @brief Returns the data for the specified value at the specified path.
 *
 * @param name The name of the value to return
 * @param type A pointer to store the type of the value, or NULL
 * @return The data for the specified value
 */
- (nullable OFData *)dataForValueNamed: (nullable OFString *)name
				  type: (nullable DWORD *)type;

/**
 * @brief Sets the data for the specified value.
 *
 * @param data The data to set the value to
 * @param name The name of the value to set
 * @param type The type for the value
 */
- (void)setData: (nullable OFData *)data
  forValueNamed: (nullable OFString *)name
	   type: (DWORD)type;

/**
 * @brief Returns the string for the specified value at the specified path.
 *
 * @param name The name of the value to return
 * @return The string for the specified value
 */
- (nullable OFString *)stringForValueNamed: (nullable OFString *)name;

/**
 * @brief Returns the string for the specified value at the specified path.
 *
 * @param name The name of the value to return
 * @param type A pointer to store the type of the value, or NULL
 * @return The string for the specified value
 */
- (nullable OFString *)stringForValueNamed: (nullable OFString *)name
				      type: (nullable DWORD *)type;

/**
 * @brief Sets the string for the specified value.
 *
 * @param string The string to set the value to
 * @param name The name of the value to set
 */
- (void)setString: (nullable OFString *)string
    forValueNamed: (nullable OFString *)name;

/**
 * @brief Sets the string for the specified value.
 *
 * @param string The string to set the value to
 * @param name The name of the value to set
 * @param type The type for the value
 */
- (void)setString: (nullable OFString *)string
    forValueNamed: (nullable OFString *)name
	     type: (DWORD)type;

/**
 * @brief Returns the DWORD for the specified value at the specified path.
 *
 * @param name The name of the value to return
 * @return The DWORD for the specified value
 */
- (uint32_t)DWORDForValueNamed: (nullable OFString *)name;

/**
 * @brief Sets the DWORD for the specified value.
 *
 * @param dword The DWORD to set the value to
 * @param name The name of the value to set
 */
- (void)setDWORD: (uint32_t)dword forValueNamed: (nullable OFString *)name;

/**
 * @brief Returns the QWORD for the specified value at the specified path.
 *
 * @param name The name of the value to return
 * @return The QWORD for the specified value
 */
- (uint64_t)QWORDForValueNamed: (nullable OFString *)name;

/**
 * @brief Sets the QWORD for the specified value.
 *
 * @param qword The QWORD to set the value to
 * @param name The name of the value to set
 */
- (void)setQWORD: (uint64_t)qword forValueNamed: (nullable OFString *)name;

/**
 * @brief Deletes the specified value.
 *
 * @param name The value to delete
 */
- (void)deleteValueNamed: (nullable OFString *)name;

/**
 * @brief Deletes the specified subkey.
 *
 * @param subkeyPath The path of the subkey to delete
 */
- (void)deleteSubkeyAtPath: (OFString *)subkeyPath;
@end

OF_ASSUME_NONNULL_END
