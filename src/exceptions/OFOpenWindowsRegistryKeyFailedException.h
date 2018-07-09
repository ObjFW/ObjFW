/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
	DWORD _options;
	REGSAM _securityAndAccessRights;
	LPSECURITY_ATTRIBUTES _Nullable _securityAttributes;
	LSTATUS _status;
}

/*!
 * @brief The registry key on which opening the sub key failed.
 */
@property (readonly, nonatomic) OFWindowsRegistryKey *registryKey;

/*!
 * @brief The path for the sub key that could not be opened.
 */
@property (readonly, nonatomic) OFString *path;

/*!
 * @brief The options for the sub key that could not be opened.
 */
@property (readonly, nonatomic) DWORD options;

/*!
 * @brief The security and access rights for the sub key that could not be
 *	  opened.
 */
@property (readonly, nonatomic) REGSAM securityAndAccessRights;

/*!
 * @brief The status returned by RegOpenKeyEx().
 */
@property (readonly, nonatomic) LSTATUS status;

/*!
 * @brief Creates a new, autoreleased open Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which opening the sub key failed
 * @param path The path for the sub key that could not be opened
 * @param options The options for the sub key that could not be opened
 * @param securityAndAccessRights The security and access rights for the sub
 *				  key that could not be opened
 * @param status The status returned by RegOpenKeyEx()
 * @return A new, autoreleased open Windows registry key failed exception
 */
+ (instancetype)
    exceptionWithRegistryKey: (OFWindowsRegistryKey *)registryKey
			path: (OFString *)path
		     options: (DWORD)options
     securityAndAccessRights: (REGSAM)securityAndAccessRights
		      status: (LSTATUS)status;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated open Windows registry key failed
 *	  exception.
 *
 * @param registryKey The registry key on which opening the sub key failed
 * @param path The path for the sub key that could not be opened
 * @param options The options for the sub key that could not be opened
 * @param securityAndAccessRights The security and access rights for the sub
 *				  key that could not be opened
 * @param status The status returned by RegOpenKeyEx()
 * @return An initialized open Windows registry key failed exception
 */
- (instancetype)
	initWithRegistryKey: (OFWindowsRegistryKey *)registryKey
		       path: (OFString *)path
		    options: (DWORD)options
    securityAndAccessRights: (REGSAM)securityAndAccessRights
		     status: (LSTATUS)status OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
