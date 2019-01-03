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

#include "config.h"

#import "OFWindowsRegistryKey.h"

#include <windows.h>

#import "OFCreateWindowsRegistryKeyFailedException.h"
#import "OFOpenWindowsRegistryKeyFailedException.h"
#import "OFReadWindowsRegistryValueFailedException.h"

@interface OFWindowsRegistryKey ()
- (instancetype)of_initWithHKey: (HKEY)hKey
			  close: (bool)close;
@end

@implementation OFWindowsRegistryKey
+ (instancetype)classesRootKey
{
	return [[[self alloc] of_initWithHKey: HKEY_CLASSES_ROOT
					close: false] autorelease];
}

+ (instancetype)currentConfigKey
{
	return [[[self alloc] of_initWithHKey: HKEY_CURRENT_CONFIG
					close: false] autorelease];
}

+ (instancetype)currentUserKey
{
	return [[[self alloc] of_initWithHKey: HKEY_CURRENT_USER
					close: false] autorelease];
}

+ (instancetype)localMachineKey
{
	return [[[self alloc] of_initWithHKey: HKEY_LOCAL_MACHINE
					close: false] autorelease];
}

+ (instancetype)usersKey
{
	return [[[self alloc] of_initWithHKey: HKEY_USERS
					close: false] autorelease];
}

- (instancetype)of_initWithHKey: (HKEY)hKey
			  close: (bool)close
{
	self = [super init];

	_hKey = hKey;
	_close = close;

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	if (_close)
		RegCloseKey(_hKey);

	[super dealloc];
}

- (OFWindowsRegistryKey *)openSubKeyWithPath: (OFString *)path
		     securityAndAccessRights: (REGSAM)securityAndAccessRights
{
	return [self openSubKeyWithPath: path
				options: 0
		securityAndAccessRights: securityAndAccessRights];
}

- (OFWindowsRegistryKey *)openSubKeyWithPath: (OFString *)path
				     options: (DWORD)options
		     securityAndAccessRights: (REGSAM)securityAndAccessRights
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;
	HKEY subKey;

	if ((status = RegOpenKeyExW(_hKey, [path UTF16String], options,
	    securityAndAccessRights, &subKey)) != ERROR_SUCCESS) {
		if (status == ERROR_FILE_NOT_FOUND) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		@throw [OFOpenWindowsRegistryKeyFailedException
		    exceptionWithRegistryKey: self
					path: path
				     options: options
		     securityAndAccessRights: securityAndAccessRights
				      status: status];
	}

	objc_autoreleasePoolPop(pool);

	return [[[OFWindowsRegistryKey alloc] of_initWithHKey: subKey
							close: true]
	    autorelease];
}

- (OFWindowsRegistryKey *)
       createSubKeyWithPath: (OFString *)path
    securityAndAccessRights: (REGSAM)securityAndAccessRights
{
	return [self createSubKeyWithPath: path
				  options: 0
		  securityAndAccessRights: securityAndAccessRights
		       securityAttributes: NULL
			      disposition: NULL];
}

- (OFWindowsRegistryKey *)
       createSubKeyWithPath: (OFString *)path
		    options: (DWORD)options
    securityAndAccessRights: (REGSAM)securityAndAccessRights
	 securityAttributes: (LPSECURITY_ATTRIBUTES)securityAttributes
		disposition: (LPDWORD)disposition
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;
	HKEY subKey;

	if ((status = RegCreateKeyExW(_hKey, [path UTF16String], 0,
	    NULL, options, securityAndAccessRights, securityAttributes,
	    &subKey, NULL)) != ERROR_SUCCESS)
		@throw [OFCreateWindowsRegistryKeyFailedException
		    exceptionWithRegistryKey: self
					path: path
				     options: options
		     securityAndAccessRights: securityAndAccessRights
			  securityAttributes: securityAttributes
				      status: status];

	objc_autoreleasePoolPop(pool);

	return [[[OFWindowsRegistryKey alloc] of_initWithHKey: subKey
							close: true]
	    autorelease];
}

- (OFString *)stringForValue: (OFString *)value
		  subKeyPath: (OFString *)subKeyPath
{
	return [self stringForValue: value
			 subKeyPath: subKeyPath
			      flags: 0
			       type: NULL];
}

- (OFString *)stringForValue: (OFString *)value
		  subKeyPath: (OFString *)subKeyPath
		       flags: (DWORD)flags
			type: (LPDWORD)type
{
	void *pool = objc_autoreleasePoolPush();
	of_char16_t stackBuffer[256], *buffer = stackBuffer;
	DWORD length = sizeof(stackBuffer);
	LSTATUS status;
	OFString *ret;

	if ((status = RegGetValueW(_hKey, [subKeyPath UTF16String],
	    [value UTF16String], flags | RRF_RT_REG_SZ | RRF_RT_REG_EXPAND_SZ,
	    type, buffer, &length)) != ERROR_SUCCESS) {
		OFObject *tmp;

		if (status == ERROR_FILE_NOT_FOUND) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		if (status != ERROR_MORE_DATA)
			@throw [OFReadWindowsRegistryValueFailedException
			    exceptionWithRegistryKey: self
					       value: value
					  subKeyPath: subKeyPath
					       flags: flags
					      status: status];

		tmp = [[[OFObject alloc] init] autorelease];
		buffer = [tmp allocMemoryWithSize: length];

		if ((status = RegGetValueW(_hKey, [subKeyPath UTF16String],
		    [value UTF16String], flags | RRF_RT_REG_SZ |
		    RRF_RT_REG_EXPAND_SZ, NULL, buffer, &length)) !=
		    ERROR_SUCCESS)
			@throw [OFReadWindowsRegistryValueFailedException
			    exceptionWithRegistryKey: self
					       value: value
					  subKeyPath: subKeyPath
					       flags: flags
					      status: status];
	}

	/*
	 * We do not specify a length, as the length returned by RegGetValue()
	 * sometimes seems to be larger than the string.
	 */
	ret = [[OFString alloc] initWithUTF16String: buffer];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
