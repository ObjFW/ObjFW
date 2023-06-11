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
#import "OFOnce.h"
#import "OFSocket.h"
#import "OFString.h"

#include <windows.h>
#define interface struct
#include <iphlpapi.h>
#undef interface

static WINAPI ULONG (*GetAdaptersAddressesFuncPtr)(ULONG, ULONG, PVOID,
    PIP_ADAPTER_ADDRESSES, PULONG);

static void
init(void)
{
	HMODULE module;

	if ((module = LoadLibrary("iphlpapi.dll")) != NULL)
		GetAdaptersAddressesFuncPtr = (WINAPI ULONG (*)(ULONG, ULONG,
		    PVOID, PIP_ADAPTER_ADDRESSES, PULONG))
		    GetProcAddress(module, "GetAdaptersAddresses");

}

static OFMutableDictionary OF_GENERIC(OFString *, OFNetworkInterface) *
networkInterfacesFromGetAdaptersAddresses(void)
{
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	OFStringEncoding encoding = [OFLocale encoding];
	ULONG adapterAddressesSize = sizeof(IP_ADAPTER_ADDRESSES);
	PIP_ADAPTER_ADDRESSES adapterAddresses;

	if ((adapterAddresses = malloc(adapterAddressesSize)) == NULL)
		return nil;

	@try {
		ULONG error = GetAdaptersAddressesFuncPtr(AF_UNSPEC, 0, NULL,
		    adapterAddresses, &adapterAddressesSize);

		if (error == ERROR_BUFFER_OVERFLOW) {
			PIP_ADAPTER_ADDRESSES newAdapterAddresses =
			    realloc(adapterAddresses, adapterAddressesSize);

			if (newAdapterAddresses == NULL)
				return nil;

			adapterAddresses = newAdapterAddresses;
			error = GetAdaptersAddressesFuncPtr(AF_UNSPEC, 0, NULL,
			    adapterAddresses, &adapterAddressesSize);
		}

		if (error != ERROR_SUCCESS)
			return nil;

		for (PIP_ADAPTER_ADDRESSES iter = adapterAddresses;
		    iter != NULL; iter = iter->Next) {
			OFString *name;
			OFMutableDictionary *interface;
			OFNumber *index;

			name = [OFString stringWithCString: iter->AdapterName
						  encoding: encoding];

			if ((interface = [ret objectForKey: name]) == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			index = [OFNumber numberWithUnsignedInt: iter->IfIndex];
			[interface setObject: index
				      forKey: OFNetworkInterfaceIndex];

			if (iter->PhysicalAddressLength > 0) {
				const OFNetworkInterfaceKey key =
				    OFNetworkInterfaceHardwareAddress;
				OFData *address = [OFData
				    dataWithItems: iter->PhysicalAddress
					    count: iter->PhysicalAddressLength];
				[interface setObject: address forKey: key];
			}

			for (PIP_ADAPTER_UNICAST_ADDRESS_LH addrIter =
			    iter->FirstUnicastAddress; addrIter != NULL;
			    addrIter = addrIter->Next) {
				OFSocketAddress address;
				int length;
				OFNetworkInterfaceKey key;
				OFMutableData *addresses;

				length = (int)sizeof(address.sockaddr);
				if (length > addrIter->Address.iSockaddrLength)
					length =
					    addrIter->Address.iSockaddrLength;

				memset(&address, 0, sizeof(OFSocketAddress));
				memcpy(&address.sockaddr,
				    addrIter->Address.lpSockaddr,
				    (size_t)length);

				switch (address.sockaddr.in.sin_family) {
				case AF_INET:
					address.family =
					    OFSocketAddressFamilyIPv4;
					key = OFNetworkInterfaceIPv4Addresses;
					break;
				case AF_INET6:
					address.family =
					    OFSocketAddressFamilyIPv6;
					key = OFNetworkInterfaceIPv6Addresses;
					break;
				default:
					continue;
				}

				addresses = [interface objectForKey: key];
				if (addresses == nil) {
					addresses = [OFMutableData
					    dataWithItemSize:
					    sizeof(OFSocketAddress)];
					[interface setObject: addresses
						      forKey: key];
				}

				[addresses addItem: &address];
			}

			[[interface objectForKey:
			    OFNetworkInterfaceIPv4Addresses] makeImmutable];
			[[interface objectForKey:
			    OFNetworkInterfaceIPv6Addresses] makeImmutable];
		}
	} @finally {
		free(adapterAddresses);
	}

	return ret;
}

static OFMutableDictionary OF_GENERIC(OFString *, OFNetworkInterface) *
networkInterfacesFromGetAdaptersInfo(void)
{
	OFMutableDictionary *ret = [OFMutableDictionary dictionary];
	OFStringEncoding encoding = [OFLocale encoding];
	ULONG adapterInfoSize = sizeof(IP_ADAPTER_INFO);
	PIP_ADAPTER_INFO adapterInfo;

	if ((adapterInfo = malloc(adapterInfoSize)) == NULL)
		return nil;

	@try {
		ULONG error = GetAdaptersInfo(adapterInfo, &adapterInfoSize);

		if (error == ERROR_BUFFER_OVERFLOW) {
			PIP_ADAPTER_INFO newAdapterInfo =
			    realloc(adapterInfo, adapterInfoSize);

			if (newAdapterInfo == NULL)
				return nil;

			adapterInfo = newAdapterInfo;
			error = GetAdaptersInfo(adapterInfo, &adapterInfoSize);
		}

		if (error != ERROR_SUCCESS)
			return nil;

		for (PIP_ADAPTER_INFO iter = adapterInfo; iter != NULL;
		    iter = iter->Next) {
			OFMutableDictionary *interface;
			OFString *name, *IPString;
			OFNumber *index;
			OFSocketAddress IPv4Address;
			OFData *addresses;

			name = [OFString stringWithCString: iter->AdapterName
						  encoding: encoding];

			if ((interface = [ret objectForKey: name]) == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			index = [OFNumber numberWithUnsignedInt: iter->Index];
			[interface setObject: index
				      forKey: OFNetworkInterfaceIndex];

			if (iter->AddressLength > 0) {
				const OFNetworkInterfaceKey key =
				    OFNetworkInterfaceHardwareAddress;
				OFData *address = [OFData
				    dataWithItems: iter->Address
					    count: iter->AddressLength];
				[interface setObject: address forKey: key];
			}

			IPString = [OFString
			    stringWithCString: iter->IpAddressList.IpAddress
						   .String
				     encoding: encoding];

			if ([IPString isEqual: @"0.0.0.0"])
				continue;

			IPv4Address = OFSocketAddressParseIPv4(IPString, 0);
			addresses = [OFData dataWithItems: &IPv4Address
						    count: 1
						 itemSize: sizeof(IPv4Address)];
			[interface setObject: addresses
				      forKey: OFNetworkInterfaceIPv4Addresses];
		}
	} @finally {
		free(adapterInfo);
	}

	return ret;
}

@implementation OFSystemInfo (NetworkInterfaces)
+ (OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)networkInterfaces
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *ret;
	OFEnumerator *enumerator;
	OFMutableDictionary *interface;

	OFOnce(&onceControl, init);

	if (GetAdaptersAddressesFuncPtr != NULL)
		ret = networkInterfacesFromGetAdaptersAddresses();
	else
		ret = networkInterfacesFromGetAdaptersInfo();

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[interface makeImmutable];

	[ret makeImmutable];
	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
