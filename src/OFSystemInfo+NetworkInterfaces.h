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
