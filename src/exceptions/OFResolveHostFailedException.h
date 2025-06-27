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

#import "OFException.h"
#import "OFDNSResolver.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFResolveHostFailedException OFResolveHostFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that resolving a host failed.
 */
@interface OFResolveHostFailedException: OFException
{
	OFString *_host;
	OFSocketAddressFamily _addressFamily;
	OFDNSResolverErrorCode _errorCode;
	OF_RESERVE_IVARS(OFResolveHostFailedException, 4)
}

/**
 * @brief The host which could not be resolved.
 */
@property (readonly, nonatomic) OFString *host;

/**
 * @brief The address family for which the host could not be resolved.
 */
@property (readonly, nonatomic) OFSocketAddressFamily addressFamily;

/**
 * @brief The error code from the resolver.
 */
@property (readonly, nonatomic) OFDNSResolverErrorCode errorCode;

/**
 * @brief Creates a new, autoreleased resolve host failed exception.
 *
 * @param host The host which could not be resolved
 * @param addressFamily The address family for which the host could not be
 *			resolved
 * @param errorCode The error code from the resolver
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithHost: (OFString *)host
		    addressFamily: (OFSocketAddressFamily)addressFamily
			errorCode: (OFDNSResolverErrorCode)errorCode;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated resolve host failed exception.
 *
 * @param host The host which could not be resolved
 * @param addressFamily The address family for which the host could not be
 *			resolved
 * @param errorCode The error code from the resolver
 * @return An initialized address translation failed exception
 */
- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (OFSocketAddressFamily)addressFamily
		   errorCode: (OFDNSResolverErrorCode)errorCode;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
