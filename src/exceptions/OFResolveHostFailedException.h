/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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
#import "OFDNSResolver.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFResolveHostFailedException \
 *	  OFResolveHostFailedException.h ObjFW/OFResolveHostFailedException.h
 *
 * @brief An exception indicating that resolving a host failed.
 */
@interface OFResolveHostFailedException: OFException
{
	OFString *_host;
	of_socket_address_family_t _addressFamily;
	of_dns_resolver_error_t _error;
}

/**
 * @brief The host which could not be resolved.
 */
@property (readonly, nonatomic) OFString *host;

/**
 * @brief The address family for which the host could not be resolved.
 */
@property (readonly, nonatomic) of_socket_address_family_t addressFamily;

/**
 * @brief The error from the resolver.
 */
@property (readonly, nonatomic) of_dns_resolver_error_t error;

/**
 * @brief Creates a new, autoreleased resolve host failed exception.
 *
 * @param host The host which could not be resolved
 * @param addressFamily The address family for which the host could not be
 *			resolved
 * @param error The error from the resolver
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithHost: (OFString *)host
		    addressFamily: (of_socket_address_family_t)addressFamily
			    error: (of_dns_resolver_error_t)error;

/**
 * @brief Initializes an already allocated resolve host failed exception.
 *
 * @param host The host which could not be resolved
 * @param addressFamily The address family for which the host could not be
 *			resolved
 * @param error The error from the resolver
 * @return An initialized address translation failed exception
 */
- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (of_socket_address_family_t)addressFamily
		       error: (of_dns_resolver_error_t)error;
@end

OF_ASSUME_NONNULL_END
