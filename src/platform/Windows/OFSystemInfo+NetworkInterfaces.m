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

#include "config.h"

#import "OFSystemInfo.h"
#import "OFSystemInfo+NetworkInterfaces.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSocket.h"
#import "OFString.h"

#include <windows.h>
#define interface struct
#include <iphlpapi.h>
#undef interface

@implementation OFSystemInfo (NetworkInterfaces)
+ (OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)networkInterfaces
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	OFStringEncoding encoding = [OFLocale encoding];
	ULONG adapterInfoSize;
	PIP_ADAPTER_INFO adapterInfo;
	OFEnumerator *enumerator;
	OFMutableDictionary *interface;

	adapterInfoSize = sizeof(IP_ADAPTER_INFO);
	if ((adapterInfo = malloc(adapterInfoSize)) == NULL) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	@try {
		ULONG error = GetAdaptersInfo(adapterInfo, &adapterInfoSize);

		if (error == ERROR_BUFFER_OVERFLOW) {
			PIP_ADAPTER_INFO newAdapterInfo = realloc(
			    adapterInfo, adapterInfoSize);

			if (newAdapterInfo == NULL) {
				objc_autoreleasePoolPop(pool);
				return nil;
			}

			adapterInfo = newAdapterInfo;
			error = GetAdaptersInfo(adapterInfo, &adapterInfoSize);
		}

		if (error != ERROR_SUCCESS) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		for (PIP_ADAPTER_INFO iter = adapterInfo; iter != NULL;
		    iter = iter->Next) {
			OFString *name, *IPString;
			OFNumber *index;
			OFMutableData *addresses;
			OFSocketAddress address;

			name = [OFString stringWithCString: iter->AdapterName
						  encoding: encoding];

			if ((interface = [ret objectForKey: name]) == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			index = [OFNumber numberWithUnsignedInt: iter->Index];
			[interface setObject: index
				      forKey: OFNetworkInterfaceIndex];

			IPString = [OFString
			    stringWithCString: iter->IpAddressList.IpAddress
						   .String
				     encoding: encoding];

			if ([IPString isEqual: @"0.0.0.0"])
				continue;

			if ((addresses = [interface objectForKey:
			    OFNetworkInterfaceIPv4Addresses]) == nil) {
				addresses = [OFMutableData
				    dataWithItemSize: sizeof(OFSocketAddress)];
				[interface
				    setObject: addresses
				       forKey: OFNetworkInterfaceIPv4Addresses];
			}

			address = OFSocketAddressParseIPv4(IPString, 0);
			[addresses addItem: &address];
		}
	} @finally {
		free(adapterInfo);
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[interface makeImmutable];

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
