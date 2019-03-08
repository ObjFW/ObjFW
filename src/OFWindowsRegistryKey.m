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
#import "OFData.h"

#include <windows.h>

#import "OFCreateWindowsRegistryKeyFailedException.h"
#import "OFDeleteWindowsRegistryKeyFailedException.h"
#import "OFDeleteWindowsRegistryValueFailedException.h"
#import "OFGetWindowsRegistryValueFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenWindowsRegistryKeyFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFSetWindowsRegistryValueFailedException.h"

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

- (OFWindowsRegistryKey *)openSubkeyAtPath: (OFString *)path
		   securityAndAccessRights: (REGSAM)securityAndAccessRights
{
	return [self openSubkeyAtPath: path
			      options: 0
	      securityAndAccessRights: securityAndAccessRights];
}

- (OFWindowsRegistryKey *)openSubkeyAtPath: (OFString *)path
				   options: (DWORD)options
		   securityAndAccessRights: (REGSAM)securityAndAccessRights
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;
	HKEY subKey;

	if ((status = RegOpenKeyExW(_hKey, path.UTF16String, options,
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

- (OFWindowsRegistryKey *)createSubkeyAtPath: (OFString *)path
		     securityAndAccessRights: (REGSAM)securityAndAccessRights
{
	return [self createSubkeyAtPath: path
				options: 0
		securityAndAccessRights: securityAndAccessRights
		     securityAttributes: NULL
			    disposition: NULL];
}

- (OFWindowsRegistryKey *)
	 createSubkeyAtPath: (OFString *)path
		    options: (DWORD)options
    securityAndAccessRights: (REGSAM)securityAndAccessRights
	 securityAttributes: (LPSECURITY_ATTRIBUTES)securityAttributes
		disposition: (LPDWORD)disposition
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;
	HKEY subKey;

	if ((status = RegCreateKeyExW(_hKey, path.UTF16String, 0,
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

- (OFData *)dataForValue: (OFString *)value
	      subkeyPath: (OFString *)subkeyPath
		   flags: (DWORD)flags
		    type: (LPDWORD)type
{
	void *pool = objc_autoreleasePoolPush();
	char stackBuffer[256], *buffer = stackBuffer;
	DWORD length = sizeof(stackBuffer);
	OFMutableData *ret = nil;
	LSTATUS status;

	for (;;) {
		status = RegGetValueW(_hKey, subkeyPath.UTF16String,
		    value.UTF16String, flags, type, buffer, &length);

		switch (status) {
		case ERROR_SUCCESS:
			if (buffer == stackBuffer) {
				objc_autoreleasePoolPop(pool);

				return [OFData dataWithItems: buffer
						       count: length];
			} else {
				[ret makeImmutable];
				[ret retain];

				objc_autoreleasePoolPop(pool);

				return [ret autorelease];
			}
		case ERROR_FILE_NOT_FOUND:
			objc_autoreleasePoolPop(pool);

			return nil;
		case ERROR_MORE_DATA:
			objc_autoreleasePoolPop(pool);
			pool = objc_autoreleasePoolPush();

			ret = [OFMutableData dataWithCapacity: length];
			[ret increaseCountBy: length];
			buffer = ret.items;

			continue;
		default:
			@throw [OFGetWindowsRegistryValueFailedException
			    exceptionWithRegistryKey: self
					       value: value
					  subkeyPath: subkeyPath
					       flags: flags
					      status: status];
		}
	}
}

- (void)setData: (OFData *)data
       forValue: (OFString *)value
	   type: (DWORD)type
{
	size_t length = data.count * data.itemSize;
	LSTATUS status;

	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if ((status = RegSetValueExW(_hKey, value.UTF16String, 0, type,
	    data.items, (DWORD)length)) != ERROR_SUCCESS)
		@throw [OFSetWindowsRegistryValueFailedException
		    exceptionWithRegistryKey: self
				       value: value
					data: data
					type: type
				      status: status];
}

- (OFString *)stringForValue: (OFString *)value
		  subkeyPath: (OFString *)subkeyPath
{
	return [self stringForValue: value
			 subkeyPath: subkeyPath
			      flags: RRF_RT_REG_SZ
			       type: NULL];
}

- (OFString *)stringForValue: (OFString *)value
		  subkeyPath: (OFString *)subkeyPath
		       flags: (DWORD)flags
			type: (LPDWORD)type
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [self dataForValue: value
			       subkeyPath: subkeyPath
				    flags: flags
				     type: type];
	const of_char16_t *UTF16String;
	size_t length;
	OFString *ret;

	if (data == nil)
		return nil;

	UTF16String = data.items;
	length = data.count;

	if (data.itemSize != 1 || length % 2 == 1)
		@throw [OFInvalidFormatException exception];

	length /= 2;

	/*
	 * REG_SZ and REG_EXPAND_SZ contain a \0, but can contain data after it
	 * that should be ignored.
	 */
	for (size_t i = 0; i < length; i++) {
		if (UTF16String[i] == 0) {
			length = i;
			break;
		}
	}

	ret = [[OFString alloc] initWithUTF16String: UTF16String
					     length: length];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)setString: (OFString *)string
	 forValue: (OFString *)value
{
	[self setString: string
	       forValue: value
		   type: REG_SZ];
}

- (void)setString: (OFString *)string
	 forValue: (OFString *)value
	     type: (DWORD)type
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data;

	data = [OFData dataWithItems: string.UTF16String
			    itemSize: sizeof(of_char16_t)
			       count: string.UTF16StringLength + 1];
	[self setData: data
	     forValue: value
		 type: type];

	objc_autoreleasePoolPop(pool);
}

- (void)deleteValue: (OFString *)value
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;

	if ((status = RegDeleteValueW(_hKey, value.UTF16String)) !=
	    ERROR_SUCCESS)
		@throw [OFDeleteWindowsRegistryValueFailedException
		    exceptionWithRegistryKey: self
				       value: value
				      status: status];

	objc_autoreleasePoolPop(pool);
}

- (void)deleteSubkeyAtPath: (OFString *)subkeyPath
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;

	if ((status = RegDeleteKeyW(_hKey, subkeyPath.UTF16String)) !=
	    ERROR_SUCCESS)
		@throw [OFDeleteWindowsRegistryKeyFailedException
		    exceptionWithRegistryKey: self
				  subkeyPath: subkeyPath
				      status: status];

	objc_autoreleasePoolPop(pool);
}
@end
