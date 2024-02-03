/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

OFNetworkInterfaceKey OFNetworkInterfaceIndex = @"OFNetworkInterfaceIndex";
OFNetworkInterfaceKey OFNetworkInterfaceHardwareAddress =
    @"OFNetworkInterfaceHardwareAddress";
OFNetworkInterfaceKey OFNetworkInterfaceIPv4Addresses =
    @"OFNetworkInterfaceIPv4Addresses";
#ifdef OF_HAVE_IPV6
OFNetworkInterfaceKey OFNetworkInterfaceIPv6Addresses =
    @"OFNetworkInterfaceIPv6Addresses";
#endif
#ifdef OF_HAVE_IPX
OFNetworkInterfaceKey OFNetworkInterfaceIPXAddresses =
    @"OFNetworkInterfaceIPXAddresses";
#endif
#ifdef OF_HAVE_APPLETALK
OFNetworkInterfaceKey OFNetworkInterfaceAppleTalkAddresses =
    @"OFNetworkInterfaceAppleTalkAddresses";
#endif

#ifdef OF_WINDOWS
# include "platform/Windows/OFSystemInfo+NetworkInterfaces.m"
#else
# include "platform/POSIX/OFSystemInfo+NetworkInterfaces.m"
#endif
