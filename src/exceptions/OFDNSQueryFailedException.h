/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFDNSQuery.h"
#import "OFDNSResolver.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFDNSQueryFailedException \
 *	  OFDNSQueryFailedException.h ObjFW/OFDNSQueryFailedException.h
 *
 * @brief An exception indicating the resolving a host failed.
 */
@interface OFDNSQueryFailedException: OFException
{
	OFDNSQuery *_query;
	of_dns_resolver_error_t _error;
}

/*!
 * @brief The query which could not be performed.
 */
@property (readonly, nonatomic) OFDNSQuery *query;

/*!
 * @brief The error from the resolver.
 */
@property (readonly, nonatomic) of_dns_resolver_error_t error;

/*!
 * @brief Creates a new, autoreleased resolve host failed exception.
 *
 * @param query The query which could not be performed
 * @param error The error from the resolver
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithQuery: (OFDNSQuery *)query
			     error: (of_dns_resolver_error_t)error;

/*!
 * @brief Initializes an already allocated address translation failed exception.
 *
 * @param query The query which could not be performed
 * @param error The error from the resolver
 * @return An initialized address translation failed exception
 */
- (instancetype)initWithQuery: (OFDNSQuery *)query
			error: (of_dns_resolver_error_t)error;
@end

OF_ASSUME_NONNULL_END
