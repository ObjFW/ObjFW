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

#import "OFObject.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

typedef OFDictionary OF_GENERIC(OFString *, OFArray OF_GENERIC(
    OF_KINDOF(OFDNSResourceRecord *)) *) *of_dns_response_records_t;

/*!
 * @class OFDNSResponse OFDNSResponse.h ObjFW/OFDNSResponse.h
 *
 * @brief A class storing a response from @ref OFDNSResolver.
 */
@interface OFDNSResponse: OFObject
{
	of_dns_response_records_t _Nullable _answerRecords;
	of_dns_response_records_t _Nullable _authorityRecords;
	of_dns_response_records_t _Nullable _additionalRecords;
	OF_RESERVE_IVARS(4)
}

/*!
 * @brief The answer records of the response.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, readonly)
    of_dns_response_records_t answerRecords;

/*!
 * @brief The authority records of the response.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, readonly)
    of_dns_response_records_t authorityRecords;

/*!
 * @brief The additional records of the response.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, readonly)
    of_dns_response_records_t additionalRecords;

/*!
 * @brief Creates a new, autoreleased OFDNSResponse.
 *
 * @param answerRecords The answer records of the response
 * @param authorityRecords The authority records of the response
 * @param additionalRecords The additional records of the response
 * @return A new, autoreleased OFDNSResponse
 */
+ (instancetype)
    responseWithAnswerRecords: (nullable of_dns_response_records_t)answerRecords
	     authorityRecords: (nullable of_dns_response_records_t)
				   authorityRecords
	    additionalRecords: (nullable of_dns_response_records_t)
				   additionalRecords;

/*!
 * @brief Initializes an already allocated OFDNSResponse.
 *
 * @param answerRecords The answer records of the response
 * @param authorityRecords The authority records of the response
 * @param additionalRecords The additional records of the response
 * @return An initialized OFDNSResponse
 */
- (instancetype)
    initWithAnswerRecords: (nullable of_dns_response_records_t)answerRecords
	 authorityRecords: (nullable of_dns_response_records_t)authorityRecords
	additionalRecords: (nullable of_dns_response_records_t)additionalRecords
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
