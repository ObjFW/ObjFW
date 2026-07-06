/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#ifdef OF_AMIGAOS
# undef OFNetworkInterfaceIndex
# undef OFNetworkInterfaceHardwareAddress
# undef OFNetworkInterfaceIPv4Addresses
# ifdef OF_HAVE_IPV6
#  undef OFNetworkInterfaceIPv6Addresses
# endif
# ifdef OF_HAVE_IPX
#  undef OFNetworkInterfaceIPXAddresses
# endif
# ifdef OF_HAVE_APPLETALK
#  undef OFNetworkInterfaceAppleTalkAddresses
# endif
#endif

const OFNetworkInterfaceKey OFNetworkInterfaceIndex =
    @"OFNetworkInterfaceIndex";
const OFNetworkInterfaceKey OFNetworkInterfaceHardwareAddress =
    @"OFNetworkInterfaceHardwareAddress";
const OFNetworkInterfaceKey OFNetworkInterfaceIPv4Addresses =
    @"OFNetworkInterfaceIPv4Addresses";
#ifdef OF_HAVE_IPV6
const OFNetworkInterfaceKey OFNetworkInterfaceIPv6Addresses =
    @"OFNetworkInterfaceIPv6Addresses";
#endif
#ifdef OF_HAVE_IPX
const OFNetworkInterfaceKey OFNetworkInterfaceIPXAddresses =
    @"OFNetworkInterfaceIPXAddresses";
#endif
#ifdef OF_HAVE_APPLETALK
const OFNetworkInterfaceKey OFNetworkInterfaceAppleTalkAddresses =
    @"OFNetworkInterfaceAppleTalkAddresses";
#endif

#ifdef OF_AMIGAOS
const OFNetworkInterfaceKey *
OFNetworkInterfaceIndexRef(void)
{
	return &OFNetworkInterfaceIndex;
}

const OFNetworkInterfaceKey *
OFNetworkInterfaceHardwareAddressRef(void)
{
	return &OFNetworkInterfaceHardwareAddress;
}

const OFNetworkInterfaceKey *
OFNetworkInterfaceIPv4AddressesRef(void)
{
	return &OFNetworkInterfaceIPv4Addresses;
}

# ifdef OF_HAVE_IPV6
const OFNetworkInterfaceKey *
OFNetworkInterfaceIPv6AddressesRef(void)
{
	return &OFNetworkInterfaceIPv6Addresses;
}
# endif

# ifdef OF_HAVE_IPX
const OFNetworkInterfaceKey *
OFNetworkInterfaceIPXAddressesRef(void)
{
	return &OFNetworkInterfaceIPXAddresses;
}
# endif

# ifdef OF_HAVE_APPLETALK
const OFNetworkInterfaceKey *
OFNetworkInterfaceAppleTalkAddressesRef(void)
{
	return &OFNetworkInterfaceAppleTalkAddresses;
}
# endif
#endif

#if defined(OF_WINDOWS)
# include "platform/Windows/OFSystemInfo+NetworkInterfaces.m"
#elif defined(OF_AMIGAOS) && !defined(OF_MORPHOS)
# include "platform/AmigaOS/OFSystemInfo+NetworkInterfaces.m"
#else
# include "platform/POSIX/OFSystemInfo+NetworkInterfaces.m"
#endif
