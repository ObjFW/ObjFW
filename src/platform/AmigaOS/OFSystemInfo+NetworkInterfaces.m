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

#import "OFSystemInfo.h"
#import "OFSystemInfo+NetworkInterfaces.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"

@implementation OFSystemInfo (NetworkInterfaces)
+ (OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)networkInterfaces
{
	void *pool;
	OFMutableDictionary *ret;
	LONG hasInterfaceAPI = 0;
	struct List *list;

	if (!_OFSocketInit())
		return nil;

	if (SocketBaseTags(SBTM_GETREF(SBTC_HAVE_INTERFACE_API),
	    (ULONG)&hasInterfaceAPI, TAG_END) != 0 || !hasInterfaceAPI)
		return nil;

	if ((list = ObtainInterfaceList()) == NULL)
		return nil;

	@try {
		pool = objc_autoreleasePoolPush();
		ret = [OFMutableDictionary dictionary];
		OFStringEncoding encoding = [OFLocale encoding];

		for (struct Node *node = list->lh_Head; node->ln_Succ != NULL;
		    node = node->ln_Succ) {
			LONG unit;
			UBYTE HWAddr[16];
			ULONG HWAddrSize;
			OFSocketAddress address;

			OFString *name;
			OFMutableDictionary *interface;

			if (QueryInterfaceTags(node->ln_Name,
			    IFQ_DeviceUnit, &unit,
			    IFQ_HardwareAddress, &HWAddr,
			    IFQ_HardwareAddressSize, &HWAddrSize,
			    IFQ_Address, &address.sockaddr.in,
			    TAG_END) != 0) {
				objc_autoreleasePoolPop(pool);
				return nil;
			}

			name = [OFString stringWithCString: node->ln_Name
						  encoding: encoding];
			interface = [OFMutableDictionary dictionary];

			[interface setObject: [OFNumber numberWithLong: unit]
				      forKey: OFNetworkInterfaceIndex];

			if (HWAddrSize == 48) {
				OFNetworkInterfaceKey key =
				    OFNetworkInterfaceHardwareAddress;
				OFData *data = [OFData dataWithItems: HWAddr
							       count: 6];

				[interface setObject: data forKey: key];
			}

			if (address.sockaddr.in.sin_family == AF_INET) {
				OFNetworkInterfaceKey key =
				    OFNetworkInterfaceIPv4Addresses;
				OFData *data;

				address.family = OFSocketAddressFamilyIPv4;
				address.length = sizeof(struct sockaddr_in);
				data = [OFData dataWithItems: &address
						       count: 1
						    itemSize: sizeof(address)];

				[interface setObject: data forKey: key];
			}

			[interface makeImmutable];

			[ret setObject: interface forKey: name];
		}
	} @finally {
		ReleaseInterfaceList(list);
	}

	[ret makeImmutable];
	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}
@end
