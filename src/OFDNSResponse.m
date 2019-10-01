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

#include "config.h"

#import "OFDNSResponse.h"
#import "OFDictionary.h"
#import "OFString.h"

@implementation OFDNSResponse
@synthesize answerRecords = _answerRecords;
@synthesize authorityRecords = _authorityRecords;
@synthesize additionalRecords = _additionalRecords;

+ (instancetype)
    responseWithAnswerRecords: (of_dns_response_records_t)answerRecords
	     authorityRecords: (of_dns_response_records_t)authorityRecords
	    additionalRecords: (of_dns_response_records_t)additionalRecords
{
	return [[[self alloc]
	    initWithAnswerRecords: answerRecords
		 authorityRecords: authorityRecords
		additionalRecords: additionalRecords] autorelease];
}

- (instancetype)
    initWithAnswerRecords: (of_dns_response_records_t)answerRecords
	 authorityRecords: (of_dns_response_records_t)authorityRecords
	additionalRecords: (of_dns_response_records_t)additionalRecords
{
	self = [super init];

	@try {
		_answerRecords = [answerRecords copy];
		_authorityRecords = [authorityRecords copy];
		_additionalRecords = [additionalRecords copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init OF_UNAVAILABLE
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_answerRecords release];
	[_authorityRecords release];
	[_additionalRecords release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFDNSResponse *other;

	if (![object isKindOfClass: [OFDNSResponse class]])
		return false;

	other = object;

	if (other->_answerRecords != _answerRecords &&
	    ![other->_answerRecords isEqual: _answerRecords])
		return false;
	if (other->_authorityRecords != _authorityRecords &&
	    ![other->_authorityRecords isEqual: _authorityRecords])
		return false;
	if (other->_additionalRecords != _additionalRecords &&
	    ![other->_additionalRecords isEqual: _additionalRecords])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);
	OF_HASH_ADD_HASH(hash, [_answerRecords hash]);
	OF_HASH_ADD_HASH(hash, [_authorityRecords hash]);
	OF_HASH_ADD_HASH(hash, [_additionalRecords hash]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	OFString *answerRecords = [_answerRecords.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *authorityRecords = [_authorityRecords.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *additionalRecords = [_additionalRecords.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tAnswer records = %@\n"
	    @"\tAuthority records = %@\n"
	    @"\tAdditional records = %@\n"
	    @">",
	    self.className, answerRecords, authorityRecords, additionalRecords];
}
@end
