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
#import "OFDNSQuery.h"
#import "OFDNSResolver.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFDNSQueryFailedException \
 *	  OFDNSQueryFailedException.h ObjFW/OFDNSQueryFailedException.h
 *
 * @brief An exception indicating that a DNS query failed.
 */
@interface OFDNSQueryFailedException: OFException
{
	OFDNSQuery *_query;
	of_dns_resolver_error_t _error;
}

/**
 * @brief The query which could not be performed.
 */
@property (readonly, nonatomic) OFDNSQuery *query;

/**
 * @brief The error from the resolver.
 */
@property (readonly, nonatomic) of_dns_resolver_error_t error;

/**
 * @brief Creates a new, autoreleased DNS query failed exception.
 *
 * @param query The query which could not be performed
 * @param error The error from the resolver
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithQuery: (OFDNSQuery *)query
			     error: (of_dns_resolver_error_t)error;

/**
 * @brief Initializes an already allocated DNS query failed exception.
 *
 * @param query The query which could not be performed
 * @param error The error from the resolver
 * @return An initialized address translation failed exception
 */
- (instancetype)initWithQuery: (OFDNSQuery *)query
			error: (of_dns_resolver_error_t)error;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFString *of_dns_resolver_error_to_string(of_dns_resolver_error_t error);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
