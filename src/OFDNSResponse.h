/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFDNSResourceRecord.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

typedef OFDictionary OF_GENERIC(OFString *, OFArray OF_GENERIC(
    OF_KINDOF(OFDNSResourceRecord *)) *) *OFDNSResponseRecords;

/**
 * @class OFDNSResponse OFDNSResponse.h ObjFW/ObjFW.h
 *
 * @brief A class storing a response from @ref OFDNSResolver.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFDNSResponse: OFObject
{
	OFString *_domainName;
	OFDNSResponseRecords _answerRecords, _authorityRecords;
	OFDNSResponseRecords _additionalRecords;
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
