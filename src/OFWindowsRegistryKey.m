/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFWindowsRegistryKey.h"
#import "OFData.h"
#import "OFLocale.h"
#import "OFSystemInfo.h"

#include <windows.h>

#import "OFCreateWindowsRegistryKeyFailedException.h"
#import "OFDeleteWindowsRegistryKeyFailedException.h"
#import "OFDeleteWindowsRegistryValueFailedException.h"
#import "OFGetWindowsRegistryValueFailedException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenWindowsRegistryKeyFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFSetWindowsRegistryValueFailedException.h"
#import "OFUndefinedKeyException.h"

OF_DIRECT_MEMBERS
@interface OFWindowsRegistryKey ()
- (instancetype)of_initWithHKey: (HKEY)hKey close: (bool)close;
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

- (instancetype)of_initWithHKey: (HKEY)hKey close: (bool)close
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
			      accessRights: (REGSAM)accessRights
				   options: (DWORD)options
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;
	HKEY subKey;

	if ([OFSystemInfo isWindowsNT])
		status = RegOpenKeyExW(_hKey, path.UTF16String, options,
		    accessRights, &subKey);
	else
		status = RegOpenKeyExA(_hKey,
		    [path cStringWithEncoding: [OFLocale encoding]], options,
		    accessRights, &subKey);

	if (status != ERROR_SUCCESS)
		@throw [OFOpenWindowsRegistryKeyFailedException
		    exceptionWithRegistryKey: self
					path: path
				accessRights: accessRights
				     options: options
				      status: status];

	objc_autoreleasePoolPop(pool);

	return [[[OFWindowsRegistryKey alloc] of_initWithHKey: subKey
							close: true]
	    autorelease];
}

- (OFWindowsRegistryKey *)
    createSubkeyAtPath: (OFString *)path
	  accessRights: (REGSAM)accessRights
    securityAttributes: (LPSECURITY_ATTRIBUTES)securityAttributes
	       options: (DWORD)options
	   disposition: (DWORD *)disposition
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;
	HKEY subKey;

	if ([OFSystemInfo isWindowsNT])
		status = RegCreateKeyExW(_hKey, path.UTF16String, 0,
		    NULL, options, accessRights, securityAttributes, &subKey,
		    NULL);
	else
		status = RegCreateKeyExA(_hKey,
		    [path cStringWithEncoding: [OFLocale encoding]], 0, NULL,
		    options, accessRights, securityAttributes, &subKey, NULL);

	if (status != ERROR_SUCCESS)
		@throw [OFCreateWindowsRegistryKeyFailedException
		    exceptionWithRegistryKey: self
					path: path
				accessRights: accessRights
			  securityAttributes: securityAttributes
				     options: options
				      status: status];

	objc_autoreleasePoolPop(pool);

	return [[[OFWindowsRegistryKey alloc] of_initWithHKey: subKey
							close: true]
	    autorelease];
}

- (OFData *)dataForValueNamed: (OFString *)name type: (DWORD *)type
{
	void *pool = objc_autoreleasePoolPush();
	BYTE stackBuffer[256], *buffer = stackBuffer;
	DWORD length = sizeof(stackBuffer);
	OFMutableData *ret = nil;
	bool winNT = [OFSystemInfo isWindowsNT];
	LSTATUS status;

	for (;;) {
		if (winNT)
			status = RegQueryValueExW(_hKey, name.UTF16String,
			    NULL, type, buffer, &length);
		else
			status = RegQueryValueExA(_hKey,
			    [name cStringWithEncoding: [OFLocale encoding]],
			    NULL, type, buffer, &length);

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
			buffer = ret.mutableItems;

			continue;
		default:
			@throw [OFGetWindowsRegistryValueFailedException
			    exceptionWithRegistryKey: self
					   valueName: name
					      status: status];
		}
	}
}

- (void)setData: (OFData *)data
  forValueNamed: (OFString *)name
	   type: (DWORD)type
{
	size_t length = data.count * data.itemSize;
	LSTATUS status;

	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if ([OFSystemInfo isWindowsNT])
		status = RegSetValueExW(_hKey, name.UTF16String, 0, type,
		    data.items, (DWORD)length);
	else
		status = RegSetValueExA(_hKey,
		    [name cStringWithEncoding: [OFLocale encoding]], 0, type,
		    data.items, (DWORD)length);

	if (status != ERROR_SUCCESS)
		@throw [OFSetWindowsRegistryValueFailedException
		    exceptionWithRegistryKey: self
				   valueName: name
					data: data
					type: type
				      status: status];
}

- (OFString *)stringForValueNamed: (OFString *)name
{
	return [self stringForValueNamed: name type: NULL];
}

- (OFString *)stringForValueNamed: (OFString *)name type: (DWORD *)typeOut
{
	void *pool = objc_autoreleasePoolPush();
	DWORD type;
	OFData *data = [self dataForValueNamed: name type: &type];
	OFString *ret;

	if (data == nil)
		return nil;

	if (type != REG_SZ && type != REG_EXPAND_SZ && type != REG_LINK)
		@throw [OFInvalidEncodingException exception];

	if (data.itemSize != 1)
		@throw [OFInvalidFormatException exception];

	if ([OFSystemInfo isWindowsNT]) {
		const OFChar16 *UTF16String = data.items;
		size_t length = data.count;

		if (length % 2 == 1)
			@throw [OFInvalidFormatException exception];

		length /= 2;

		/*
		 * REG_SZ and REG_EXPAND_SZ contain a \0, but can contain data
		 * after it that should be ignored.
		 */
		for (size_t i = 0; i < length; i++) {
			if (UTF16String[i] == 0) {
				length = i;
				break;
			}
		}

		ret = [[OFString alloc] initWithUTF16String: UTF16String
						     length: length];
	} else {
		const char *cString = data.items;
		size_t length = data.count;

		/*
		 * REG_SZ and REG_EXPAND_SZ contain a \0, but can contain data
		 * after it that should be ignored.
		 */
		for (size_t i = 0; i < length; i++) {
			if (cString[i] == 0) {
				length = i;
				break;
			}
		}

		ret = [[OFString alloc] initWithCString: cString
					       encoding: [OFLocale encoding]
						 length: length];
	}

	if (typeOut != NULL)
		*typeOut = type;

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (void)setString: (OFString *)string forValueNamed: (OFString *)name
{
	[self setString: string forValueNamed: name type: REG_SZ];
}

- (void)setString: (OFString *)string
    forValueNamed: (OFString *)name
	     type: (DWORD)type
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data;

	if ([OFSystemInfo isWindowsNT])
		data = [OFData dataWithItems: string.UTF16String
				       count: string.UTF16StringLength + 1
				    itemSize: sizeof(OFChar16)];
	else {
		OFStringEncoding encoding = [OFLocale encoding];
		const char *cString = [string cStringWithEncoding: encoding];
		size_t length = [string cStringLengthWithEncoding: encoding];

		data = [OFData dataWithItems: cString count: length + 1];
	}

	[self setData: data forValueNamed: name type: type];

	objc_autoreleasePoolPop(pool);
}

- (uint32_t)DWORDForValueNamed: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	DWORD type, ret;
	OFData *data = [self dataForValueNamed: name type: &type];

	if (data == nil)
		@throw [OFUndefinedKeyException exceptionWithObject: self
								key: name
							      value: nil];

	if (type != REG_DWORD)
		@throw [OFInvalidEncodingException exception];

	if (data.count != sizeof(ret) || data.itemSize != 1)
		@throw [OFInvalidFormatException exception];

	memcpy(&ret, data.items, sizeof(ret));

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)setDWORD: (uint32_t)dword forValueNamed: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithItems: &dword count: sizeof(dword)];
	[self setData: data forValueNamed: name type: REG_DWORD];
	objc_autoreleasePoolPop(pool);
}

- (uint64_t)QWORDForValueNamed: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	DWORD type;
	uint64_t ret;
	OFData *data = [self dataForValueNamed: name type: &type];

	if (data == nil)
		@throw [OFUndefinedKeyException exceptionWithObject: self
								key: name
							      value: nil];

	if (type != REG_QWORD)
		@throw [OFInvalidEncodingException exception];

	if (data.count != sizeof(ret) || data.itemSize != 1)
		@throw [OFInvalidFormatException exception];

	memcpy(&ret, data.items, sizeof(ret));

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)setQWORD: (uint64_t)qword forValueNamed: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithItems: &qword count: sizeof(qword)];
	[self setData: data forValueNamed: name type: REG_QWORD];
	objc_autoreleasePoolPop(pool);
}

- (void)deleteValueNamed: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;

	if ([OFSystemInfo isWindowsNT])
		status = RegDeleteValueW(_hKey, name.UTF16String);
	else
		status = RegDeleteValueA(_hKey,
		    [name cStringWithEncoding: [OFLocale encoding]]);

	if (status != ERROR_SUCCESS)
		@throw [OFDeleteWindowsRegistryValueFailedException
		    exceptionWithRegistryKey: self
				   valueName: name
				      status: status];

	objc_autoreleasePoolPop(pool);
}

- (void)deleteSubkeyAtPath: (OFString *)subkeyPath
{
	void *pool = objc_autoreleasePoolPush();
	LSTATUS status;

	if ([OFSystemInfo isWindowsNT])
		status = RegDeleteKeyW(_hKey, subkeyPath.UTF16String);
	else
		status = RegDeleteKeyA(_hKey,
		    [subkeyPath cStringWithEncoding: [OFLocale encoding]]);

	if (status != ERROR_SUCCESS)
		@throw [OFDeleteWindowsRegistryKeyFailedException
		    exceptionWithRegistryKey: self
				  subkeyPath: subkeyPath
				      status: status];

	objc_autoreleasePoolPop(pool);
}
@end
