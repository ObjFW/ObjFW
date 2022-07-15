/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
	OFDNSResolverErrorCode _errorCode;
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
extern OFString *OFDNSResolverErrorCodeDescription(
    OFDNSResolverErrorCode errorCode);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
