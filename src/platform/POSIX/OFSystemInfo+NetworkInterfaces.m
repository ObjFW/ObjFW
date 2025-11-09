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

#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif
#ifdef OF_HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif
#ifdef HAVE_SYS_SOCKIO_H
# include <sys/sockio.h>
#endif
#ifdef HAVE_NET_IF_H
# include <net/if.h>
#endif
#ifdef HAVE_NET_IF_ARP_H
# include <net/if_arp.h>
#endif
#ifdef HAVE_NET_IF_DL_H
# include <net/if_dl.h>
#endif
#ifdef HAVE_NET_IF_TYPES_H
# include <net/if_types.h>
#endif

#import "OFSystemInfo.h"
#import "OFSystemInfo+NetworkInterfaces.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
 #import "OFFile.h"
#endif
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"

@implementation OFSystemInfo (NetworkInterfaces)
static bool
queryNetworkInterfaceIndices(OFMutableDictionary *ret)
{
#ifdef HAVE_IF_NAMEINDEX
	OFStringEncoding encoding = [OFLocale encoding];
	struct if_nameindex *nameindex = if_nameindex();

	if (nameindex == NULL)
		return false;

	@try {
		for (size_t i = 0; nameindex[i].if_index != 0; i++) {
			OFString *name = [OFString
			    stringWithCString: nameindex[i].if_name
				     encoding: encoding];
			OFNumber *idx = [OFNumber
			    numberWithUnsignedInt: nameindex[i].if_index];
			OFMutableDictionary *interface =
			    [ret objectForKey: name];

			if (interface == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			[interface setObject: idx
				      forKey: OFNetworkInterfaceIndex];
		}
	} @finally {
		if_freenameindex(nameindex);
	}

	return true;
#else
	return false;
#endif
}

#ifdef HAVE_NET_IF_H
static bool
queryNetworkInterfaceAddresses(OFMutableDictionary *ret,
    OFNetworkInterfaceKey key, OFSocketAddressFamily addressFamily, int family,
    size_t sockaddrSize)
{
	OFStringEncoding encoding = [OFLocale encoding];
	int sock = socket(family, SOCK_DGRAM, 0);
	OFMutableDictionary *interface;
	OFEnumerator *enumerator;

	if (sock < 0)
		return false;

# if defined(HAVE_STRUCT_LIFCONF) && defined(SIOCGLIFCONF)
	struct lifconf lifc;
	struct lifreq *lifrs;

	if ((lifrs = malloc(128 * sizeof(struct lifreq))) == NULL) {
		closesocket(sock);
		return false;
	}

	@try {
		char *buffer;

		memset(&lifc, 0, sizeof(lifc));
		lifc.lifc_buf = (void *)lifrs;
		lifc.lifc_len = 128 * sizeof(struct lifreq);
		if (ioctlsocket(sock, SIOCGLIFCONF, (void *)&lifc) < 0)
			return false;

		for (buffer = lifc.lifc_buf;
		    buffer < (char *)lifc.lifc_buf + lifc.lifc_len;
		    buffer += sizeof(struct lifreq)) {
			struct lifreq *current =
			    (struct lifreq *)(void *)buffer;
			OFString *name;
			OFMutableData *addresses;
			OFSocketAddress address;

			if (current->lifr_addr.ss_family != family)
				continue;

			name = [OFString stringWithCString: current->lifr_name
						  encoding: encoding];
			if ((interface = [ret objectForKey: name]) == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			addresses = [interface objectForKey: key];
			if (addresses == nil) {
				addresses = [OFMutableData
				    dataWithItemSize: sizeof(OFSocketAddress)];
				[interface setObject: addresses forKey: key];
			}

			memset(&address, 0, sizeof(address));
			address.family = addressFamily;
			memcpy(&address.sockaddr.in, &current->lifr_addr,
			    sockaddrSize);

#  if defined(OF_HAVE_IPV6) && defined(HAVE_IF_NAMETOINDEX)
			if (address.sockaddr.in6.sin6_family == AF_INET6 &&
			    address.sockaddr.in6.sin6_addr.s6_addr[0] == 0xFE &&
			    (address.sockaddr.in6.sin6_addr.s6_addr[1] & 0xC0)
			    == 0x80)
				address.sockaddr.in6.sin6_scope_id =
				    if_nametoindex(
				    [name cStringWithEncoding: encoding]);
#  endif

			[addresses addItem: &address];
		}
	} @finally {
		free(lifrs);
		closesocket(sock);
	}
# else
	struct ifconf ifc;
	struct ifreq *ifrs;

	if (sock < 0)
		return false;

	if ((ifrs = malloc(128 * sizeof(struct ifreq))) == NULL) {
		closesocket(sock);
		return false;
	}

	@try {
		char *buffer;

		memset(&ifc, 0, sizeof(ifc));
		ifc.ifc_buf = (void *)ifrs;
		ifc.ifc_len = 128 * (int)sizeof(struct ifreq);
		if (ioctlsocket(sock, SIOCGIFCONF, (void *)&ifc) < 0)
			return false;

		buffer = ifc.ifc_buf;
		while (buffer < (char *)ifc.ifc_buf + ifc.ifc_len) {
			struct ifreq *current = (struct ifreq *)(void *)buffer;
			OFString *name;
			OFMutableData *addresses;
			OFSocketAddress address;

			if (current->ifr_addr.sa_family != family)
				goto next;

			name = [OFString stringWithCString: current->ifr_name
						  encoding: encoding];
			if ((interface = [ret objectForKey: name]) == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			addresses = [interface objectForKey: key];
			if (addresses == nil) {
				addresses = [OFMutableData
				    dataWithItemSize: sizeof(OFSocketAddress)];
				[interface setObject: addresses forKey: key];
			}

			memset(&address, 0, sizeof(address));
			address.family = addressFamily;
			memcpy(&address.sockaddr.in, &current->ifr_addr,
			    sockaddrSize);

#  if defined(OF_HAVE_IPV6) && defined(HAVE_IF_NAMETOINDEX)
			if (address.sockaddr.in6.sin6_family == AF_INET6 &&
			    address.sockaddr.in6.sin6_addr.s6_addr[0] == 0xFE &&
			    (address.sockaddr.in6.sin6_addr.s6_addr[1] & 0xC0)
			    == 0x80) {
#   if defined(__KAME__)
#    define addr6 address.sockaddr.in6.sin6_addr.s6_addr
				address.sockaddr.in6.sin6_scope_id =
				    (addr6[2] << 8) | addr6[3];
				addr6[2] = addr6[3] = 0;
#    undef addr6
#   elif defined(HAVE_IF_NAMETOINDEX)
				address.sockaddr.in6.sin6_scope_id =
				    if_nametoindex(
				    [name cStringWithEncoding: encoding]);
#   endif
			}
#  endif

			[addresses addItem: &address];

next:
#  if defined(HAVE_STRUCT_SOCKADDR_SA_LEN) && !defined(OF_NETBSD)
			if (current->ifr_addr.sa_len > sizeof(struct sockaddr))
				buffer += sizeof(struct ifreq) -
				    sizeof(struct sockaddr) +
				    current->ifr_addr.sa_len;
			else
#  endif
				buffer += sizeof(struct ifreq);
		}
	} @finally {
		free(ifrs);
		closesocket(sock);
	}
# endif

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[[interface objectForKey: key] makeImmutable];

	return true;
}
#endif

static bool
queryNetworkInterfaceIPv4Addresses(OFMutableDictionary *ret)
{
#ifdef HAVE_NET_IF_H
	return queryNetworkInterfaceAddresses(ret,
	    OFNetworkInterfaceIPv4Addresses, OFSocketAddressFamilyIPv4,
	    AF_INET, sizeof(struct sockaddr_in));
#else
	return false;
#endif
}

#ifdef OF_HAVE_IPV6
static bool
queryNetworkInterfaceIPv6Addresses(OFMutableDictionary *ret)
{
# if defined(OF_LINUX) && defined(OF_HAVE_FILES)
#  ifdef HAVE_IF_NAMETOINDEX
	OFStringEncoding encoding = [OFLocale encoding];
#  endif
	OFFile *file;
	OFString *line;
	OFMutableDictionary *interface;
	OFEnumerator *enumerator;

	@try {
		file = [OFFile fileWithPath: @"/proc/net/if_inet6" mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		return false;
	}

	while ((line = [file readLine]) != nil) {
		OFArray *components = [line
		    componentsSeparatedByString: @" "
					options: OFStringSkipEmptyComponents];
		OFString *addressString, *name;
		OFSocketAddress address;
		OFMutableData *addresses;

		if (components.count < 6)
			continue;

		addressString = [components objectAtIndex: 0];
		name = [components objectAtIndex: 5];

		if (addressString.length != 32)
			continue;

		if ((interface = [ret objectForKey: name]) == nil) {
			interface = [OFMutableDictionary dictionary];
			[ret setObject: interface forKey: name];
		}

		memset(&address, 0, sizeof(address));
		address.family = OFSocketAddressFamilyIPv6;
		address.sockaddr.in6.sin6_family = AF_INET6;

		for (size_t i = 0; i < 32; i += 2) {
			unsigned char byte;

			@try {
				byte = [[addressString
				    substringWithRange: OFMakeRange(i, 2)]
				    unsignedCharValueWithBase: 16];
			} @catch (OFInvalidFormatException *e) {
				goto next_line;
			} @catch (OFOutOfRangeException *e) {
				goto next_line;
			}

			address.sockaddr.in6.sin6_addr.s6_addr[i / 2] =
			    (unsigned char)byte;
		}

#  ifdef HAVE_IF_NAMETOINDEX
		if (address.sockaddr.in6.sin6_addr.s6_addr[0] == 0xFE &&
		    (address.sockaddr.in6.sin6_addr.s6_addr[1] & 0xC0) == 0x80)
			address.sockaddr.in6.sin6_scope_id = if_nametoindex(
			    [name cStringWithEncoding: encoding]);
#  endif

		if ((addresses = [interface
		    objectForKey: OFNetworkInterfaceIPv6Addresses]) == nil) {
			addresses = [OFMutableData
			    dataWithItemSize: sizeof(OFSocketAddress)];
			[interface setObject: addresses
				      forKey: OFNetworkInterfaceIPv6Addresses];
		}

		[addresses addItem: &address];

next_line:
		continue;
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[[interface objectForKey: OFNetworkInterfaceIPv6Addresses]
		    makeImmutable];

	return false;
# elif defined(HAVE_NET_IF_H)
	return queryNetworkInterfaceAddresses(ret,
	    OFNetworkInterfaceIPv6Addresses, OFSocketAddressFamilyIPv6,
	    AF_INET6, sizeof(struct sockaddr_in6));
# else
	return false;
# endif
}
#endif

#ifdef OF_HAVE_IPX
static bool
queryNetworkInterfaceIPXAddresses(OFMutableDictionary *ret)
{
# if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	OFFile *file;
	OFString *line;
	OFMutableDictionary *interface;
	OFEnumerator *enumerator;

	@try {
		file = [OFFile fileWithPath: @"/proc/net/ipx/interface"
				       mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		return false;
	}

	/* First line is "Network Node_Address Primary Device Frame_Type" */
	if (![[file readLine] hasPrefix: @"Network "])
		return false;

	while ((line = [file readLine]) != nil) {
		OFArray *components = [line
		    componentsSeparatedByString: @" "
					options: OFStringSkipEmptyComponents];
		OFString *name;
		unsigned long network;
		unsigned long long nodeLong;
		unsigned char node[IPX_NODE_LEN];
		OFSocketAddress address;
		OFMutableData *addresses;

		if (components.count < 5)
			continue;

		name = [components objectAtIndex: 3];

		if ((interface = [ret objectForKey: name]) == nil) {
			interface = [OFMutableDictionary dictionary];
			[ret setObject: interface forKey: name];
		}

		@try {
			network = [[components objectAtIndex: 0]
			    unsignedLongValueWithBase: 16];
			nodeLong = [[components objectAtIndex: 1]
			    unsignedLongLongValueWithBase: 16];
		} @catch (OFInvalidFormatException *e) {
			continue;
		} @catch (OFOutOfRangeException *e) {
			continue;
		}

		if (network > 0xFFFFFFFF || nodeLong > 0xFFFFFFFFFFFF)
			continue;

		node[0] = (nodeLong >> 40) & 0xFF;
		node[1] = (nodeLong >> 32) & 0xFF;
		node[2] = (nodeLong >> 24) & 0xFF;
		node[3] = (nodeLong >> 16) & 0xFF;
		node[4] = (nodeLong >> 8) & 0xFF;
		node[5] = nodeLong & 0xFF;

		address = OFSocketAddressMakeIPX((uint32_t)network, node, 0);

		if ((addresses = [interface objectForKey:
		    OFNetworkInterfaceIPXAddresses]) == nil) {
			addresses = [OFMutableData
			    dataWithItemSize: sizeof(OFSocketAddress)];
			[interface setObject: addresses
				      forKey: OFNetworkInterfaceIPXAddresses];
		}

		[addresses addItem: &address];
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[[interface objectForKey: OFNetworkInterfaceIPXAddresses]
		    makeImmutable];

	return false;
# elif defined(HAVE_NET_IF_H)
	return queryNetworkInterfaceAddresses(ret,
	    OFNetworkInterfaceIPXAddresses, OFSocketAddressFamilyIPX,
	    AF_IPX, sizeof(struct sockaddr_ipx));
# else
	return false;
# endif
}
#endif

#ifdef OF_HAVE_APPLETALK
static bool
queryNetworkInterfaceAppleTalkAddresses(OFMutableDictionary *ret)
{
# if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	OFFile *file;
	OFString *line;
	OFMutableDictionary *interface;
	OFEnumerator *enumerator;

	@try {
		file = [OFFile fileWithPath: @"/proc/net/atalk/interface"
				       mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		return false;
	}

	/* First line is "Interface Address Networks Status" */
	if (![[file readLine] hasPrefix: @"Interface "])
		return false;

	while ((line = [file readLine]) != nil) {
		OFArray *components = [line
		    componentsSeparatedByString: @" "
					options: OFStringSkipEmptyComponents];
		OFString *addressString, *name;
		unsigned short network;
		unsigned char node;
		OFSocketAddress address;
		OFMutableData *addresses;

		if (components.count < 4)
			continue;

		name = [components objectAtIndex: 0];
		addressString = [components objectAtIndex: 1];

		if (addressString.length != 7 ||
		    [addressString characterAtIndex: 4] != ':')
			continue;

		if ((interface = [ret objectForKey: name]) == nil) {
			interface = [OFMutableDictionary dictionary];
			[ret setObject: interface forKey: name];
		}

		@try {
			network = [[addressString
			    substringWithRange: OFMakeRange(0, 4)]
			    unsignedShortValueWithBase: 16];
			node = [[addressString
			    substringWithRange: OFMakeRange(5, 2)]
			    unsignedCharValueWithBase: 16];
		} @catch (OFInvalidFormatException *e) {
			continue;
		} @catch (OFOutOfRangeException *e) {
			continue;
		}

		if (network > 0xFFFF || node > 0xFF)
			continue;

		address = OFSocketAddressMakeAppleTalk(
		    (uint16_t)network, (uint8_t)node, 0);

		if ((addresses = [interface objectForKey:
		    OFNetworkInterfaceAppleTalkAddresses]) == nil) {
			addresses = [OFMutableData
			    dataWithItemSize: sizeof(OFSocketAddress)];
			[interface
			    setObject: addresses
			       forKey: OFNetworkInterfaceAppleTalkAddresses];
		}

		[addresses addItem: &address];
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[[interface objectForKey: OFNetworkInterfaceAppleTalkAddresses]
		    makeImmutable];

	return false;
# elif defined(HAVE_NET_IF_H)
	return queryNetworkInterfaceAddresses(ret,
	    OFNetworkInterfaceAppleTalkAddresses,
	    OFSocketAddressFamilyAppleTalk, AF_APPLETALK,
	    sizeof(struct sockaddr_at));
# else
	return false;
# endif
}
#endif

static bool
queryNetworkInterfaceHardwareAddress(OFMutableDictionary *ret)
{
#if defined(HAVE_NET_IF_H) && defined(SIOCGLIFHWADDR)
	OFStringEncoding encoding = [OFLocale encoding];
	int sock = socket(AF_INET, SOCK_DGRAM, 0);

	if (sock < 0)
		return false;

	for (OFString *name in ret) {
		size_t nameLength = [name cStringLengthWithEncoding: encoding];
		struct lifreq lifr;
		struct sockaddr_dl *sdl;
		OFData *hardwareAddress;

		if (nameLength > IFNAMSIZ)
			continue;

		memset(&lifr, 0, sizeof(lifr));
		memcpy(&lifr.lifr_name, [name cStringWithEncoding: encoding],
		    nameLength);

		if (ioctlsocket(sock, SIOCGLIFHWADDR, (void *)&lifr) < 0)
			continue;

		if (lifr.lifr_addr.ss_family != AF_LINK)
			continue;

		sdl = (struct sockaddr_dl *)(void *)&lifr.lifr_addr;
		hardwareAddress = [OFData dataWithItems: LLADDR(sdl)
						  count: sdl->sdl_alen];
		[[ret objectForKey: name]
		    setObject: hardwareAddress
		       forKey: OFNetworkInterfaceHardwareAddress];
	}

	return true;
#elif defined(HAVE_NET_IF_H) && defined(SIOCGIFHWADDR) && \
    defined(HAVE_STRUCT_IFREQ_IFR_HWADDR)
	OFStringEncoding encoding = [OFLocale encoding];
	int sock = socket(AF_INET, SOCK_DGRAM, 0);

	if (sock < 0)
		return false;

	for (OFString *name in ret) {
		size_t nameLength = [name cStringLengthWithEncoding: encoding];
		struct ifreq ifr;
		OFData *hardwareAddress;

		if (nameLength > IFNAMSIZ)
			continue;

		memset(&ifr, 0, sizeof(ifr));
		memcpy(&ifr.ifr_name, [name cStringWithEncoding: encoding],
		    nameLength);

		if (ioctlsocket(sock, SIOCGIFHWADDR, (void *)&ifr) < 0)
			continue;

		if (ifr.ifr_hwaddr.sa_family != ARPHRD_ETHER)
			continue;

		hardwareAddress = [OFData dataWithItems: ifr.ifr_hwaddr.sa_data
						  count: 6];
		[[ret objectForKey: name]
		    setObject: hardwareAddress
		       forKey: OFNetworkInterfaceHardwareAddress];
	}

	return true;
#elif defined(HAVE_NET_IF_H) && defined(HAVE_STRUCT_SOCKADDR_DL) && \
    defined(IFT_ETHER)
	OFStringEncoding encoding = [OFLocale encoding];
	int sock = socket(AF_INET, SOCK_DGRAM, 0);
	struct ifconf ifc;
	struct ifreq *ifrs;

	if (sock < 0)
		return false;

	ifrs = malloc(128 * sizeof(struct ifreq));
	if (ifrs == NULL) {
		closesocket(sock);
		return false;
	}

	@try {
		char *buffer;

		memset(&ifc, 0, sizeof(ifc));
		ifc.ifc_buf = (void *)ifrs;
		ifc.ifc_len = 128 * (int)sizeof(struct ifreq);
		if (ioctlsocket(sock, SIOCGIFCONF, (void *)&ifc) < 0)
			return false;

		buffer = ifc.ifc_buf;
		while (buffer < (char *)ifc.ifc_buf + ifc.ifc_len) {
			struct ifreq *current = (struct ifreq *)(void *)buffer;
			struct sockaddr_dl *sdl;
			OFString *name;
			OFMutableDictionary *interface;
			OFData *hardwareAddress;

			if (current->ifr_addr.sa_family != AF_LINK)
				goto next;

			sdl = (struct sockaddr_dl *)(void *)&current->ifr_addr;
			if (sdl->sdl_type != IFT_ETHER)
				goto next;

			name = [OFString stringWithCString: current->ifr_name
						  encoding: encoding];
			if ((interface = [ret objectForKey: name]) == nil) {
				interface = [OFMutableDictionary dictionary];
				[ret setObject: interface forKey: name];
			}

			hardwareAddress = [OFData dataWithItems: LLADDR(sdl)
							  count: sdl->sdl_alen];
			[interface
			    setObject: hardwareAddress
			       forKey: OFNetworkInterfaceHardwareAddress];

next:
# if defined(OF_MORPHOS)
			if (current->ifr_addr.sa_len +
			    sizeof(current->ifr_name) > sizeof(struct ifreq))
				buffer += current->ifr_addr.sa_len +
				    sizeof(current->ifr_name);
			else
				buffer += sizeof(struct ifreq);
# elif defined(_SIZEOF_ADDR_IFREQ)
			buffer += _SIZEOF_ADDR_IFREQ(*current);
# else
			buffer += sizeof(struct ifreq);
# endif
		}
	} @finally {
		free(ifrs);
		closesocket(sock);
	}

	return true;
#else
	return false;
#endif
}

+ (OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)networkInterfaces
{
	void *pool;
	OFMutableDictionary *ret;
	bool success = false;
	OFEnumerator *enumerator;
	OFMutableDictionary *interface;

	if (!_OFSocketInit())
		return nil;

	pool = objc_autoreleasePoolPush();
	ret = [OFMutableDictionary dictionary];

	success |= queryNetworkInterfaceIndices(ret);
	success |= queryNetworkInterfaceIPv4Addresses(ret);
#ifdef OF_HAVE_IPV6
	success |= queryNetworkInterfaceIPv6Addresses(ret);
#endif
#ifdef OF_HAVE_IPX
	success |= queryNetworkInterfaceIPXAddresses(ret);
#endif
#ifdef OF_HAVE_APPLETALK
	success |= queryNetworkInterfaceAppleTalkAddresses(ret);
#endif
	success |= queryNetworkInterfaceHardwareAddress(ret);

	if (!success) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	enumerator = [ret objectEnumerator];
	while ((interface = [enumerator nextObject]) != nil)
		[interface makeImmutable];

	[ret makeImmutable];
	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}
@end
