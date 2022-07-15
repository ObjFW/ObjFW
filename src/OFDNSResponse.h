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

#import "OFObject.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

typedef OFDictionary OF_GENERIC(OFString *, OFArray OF_GENERIC(
    OF_KINDOF(OFDNSResourceRecord *)) *) *OFDNSResponseRecords;

/**
 * @class OFDNSResponse OFDNSResponse.h ObjFW/OFDNSResponse.h
 *
 * @brief A class storing a response from @ref OFDNSResolver.
 */
@interface OFDNSResponse: OFObject
{
	OFString *_domainName;
	OFDNSResponseRecords _answerRecords, _authorityRecords;
	OFDNSResponseRecords _additionalRecords;
	OF_RESERVE_IVARS(OFDNSResponse, 4)
}

/**
 * @brief The domain name of the response.
 */
@property (readonly, nonatomic) OFString *domainName;

/**
 * @brief The answer records of the response.
 *
 * This is a dictionary with the key being the domain name and the value being
 * an array of @ref OFDNSResourceRecord.
 */
@property (readonly, nonatomic) OFDNSResponseRecords answerRecords;

/**
 * @brief The authority records of the response.
 *
 * This is a dictionary with the key being the domain name and the value being
 * an array of @ref OFDNSResourceRecord.
 */
@property (readonly, nonatomic) OFDNSResponseRecords authorityRecords;

/**
 * @brief The additional records of the response.
 *
 * This is a dictionary with the key being the domain name and the value being
 * an array of @ref OFDNSResourceRecord.
 */
@property (readonly, nonatomic) OFDNSResponseRecords additionalRecords;

/**
 * @brief Creates a new, autoreleased OFDNSResponse.
 *
 * @param domainName The domain name the response is for
 * @param answerRecords The answer records of the response
 * @param authorityRecords The authority records of the response
 * @param additionalRecords The additional records of the response
 * @return A new, autoreleased OFDNSResponse
 */
+ (instancetype)responseWithDomainName: (OFString *)domainName
			 answerRecords: (OFDNSResponseRecords)answerRecords
		      authorityRecords: (OFDNSResponseRecords)authorityRecords
		     additionalRecords: (OFDNSResponseRecords)additionalRecords;

/**
 * @brief Initializes an already allocated OFDNSResponse.
 *
 * @param domainName The domain name the response is for
 * @param answerRecords The answer records of the response
 * @param authorityRecords The authority records of the response
 * @param additionalRecords The additional records of the response
 * @return An initialized OFDNSResponse
 */
- (instancetype)initWithDomainName: (OFString *)domainName
		     answerRecords: (OFDNSResponseRecords)answerRecords
		  authorityRecords: (OFDNSResponseRecords)authorityRecords
		 additionalRecords: (OFDNSResponseRecords)additionalRecords
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
