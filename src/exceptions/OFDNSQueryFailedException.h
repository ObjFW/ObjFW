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

#import "OFException.h"
#import "OFDNSQuery.h"
#import "OFDNSResolver.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFDNSQueryFailedException OFDNSQueryFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a DNS query failed.
 */
@interface OFDNSQueryFailedException: OFException
{
	OFDNSQuery *_query;
	OFDNSResolverErrorCode _errorCode;
	OF_RESERVE_IVARS(OFDNSQueryFailedException, 4)
}

/**
 * @brief The query which could not be performed.
 */
@property (readonly, nonatomic) OFDNSQuery *query;

/**
 * @brief The error code from the resolver.
 */
@property (readonly, nonatomic) OFDNSResolverErrorCode errorCode;

/**
 * @brief Creates a new, autoreleased DNS query failed exception.
 *
 * @param query The query which could not be performed
 * @param errorCode The error from the resolver
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithQuery: (OFDNSQuery *)query
			 errorCode: (OFDNSResolverErrorCode)errorCode;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated DNS query failed exception.
 *
 * @param query The query which could not be performed
 * @param errorCode The error from the resolver
 * @return An initialized address translation failed exception
 */
- (instancetype)initWithQuery: (OFDNSQuery *)query
		    errorCode: (OFDNSResolverErrorCode)errorCode;

- (instancetype)init OF_UNAVAILABLE;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFString *_OFDNSResolverErrorCodeDescription(
    OFDNSResolverErrorCode errorCode) OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
