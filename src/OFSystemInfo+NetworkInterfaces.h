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

#import "OFSystemInfo.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A dictionary describing a network interface, as returned by
 *	  @ref networkInterfaces.
 *
 * Keys are of type @ref OFNetworkInterfaceKey.
 */
typedef OFDictionary OF_GENERIC(OFString *, id) *OFNetworkInterface;

/**
 * @brief A key of an @ref OFNetworkInterface.
 *
 * Possible values are:
 *
 *   * @ref OFNetworkInterfaceIndex
 */
typedef OFConstantString *OFNetworkInterfaceKey;

/**
 * @brief The index of a network interface.
 *
 * This maps to an @ref OFNumber.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIndex;

/**
 * @brief The hardware address of a network interface.
 *
 * This maps to an @ref OFData.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceHardwareAddress;

/**
 * @brief The IPv4 addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIPv4Addresses;

#ifdef OF_HAVE_IPV6
/**
 * @brief The IPv6 addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIPv6Addresses;
#endif

#ifdef OF_HAVE_IPX
/**
 * @brief The IPX addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceIPXAddresses;
#endif

#ifdef OF_HAVE_APPLETALK
/**
 * @brief The AppleTalk addresses of a network interface.
 *
 * This maps to an @ref OFData of @ref OFSocketAddress.
 */
extern OFNetworkInterfaceKey OFNetworkInterfaceAppleTalkAddresses;
#endif

@interface OFSystemInfo (NetworkInterfaces)

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nullable, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *networkInterfaces;
#endif

/**
 * @brief Returns the available (though not necessarily configured) network
 *	  interfaces.
 *
 * @return The available network interfaces
 */
+ (nullable OFDictionary OF_GENERIC(OFString *, OFNetworkInterface) *)
    networkInterfaces;
@end

OF_ASSUME_NONNULL_END
