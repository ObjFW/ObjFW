/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
	OFSocketAddressFamily _addressFamily;
	OFDNSResolverErrorCode _errorCode;
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
@end

OF_ASSUME_NONNULL_END
