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

#include "config.h"

#import "OFDNSResponse.h"
#import "OFDictionary.h"
#import "OFString.h"

@implementation OFDNSResponse
@synthesize domainName = _domainName, answerRecords = _answerRecords;
@synthesize authorityRecords = _authorityRecords;
@synthesize additionalRecords = _additionalRecords;

+ (instancetype)responseWithDomainName: (OFString *)domainName
			 answerRecords: (OFDNSResponseRecords)answerRecords
		      authorityRecords: (OFDNSResponseRecords)authorityRecords
		     additionalRecords: (OFDNSResponseRecords)additionalRecords
{
	return [[[self alloc]
	    initWithDomainName: domainName
		 answerRecords: answerRecords
	      authorityRecords: authorityRecords
	     additionalRecords: additionalRecords] autorelease];
}

- (instancetype)initWithDomainName: (OFString *)domainName
		     answerRecords: (OFDNSResponseRecords)answerRecords
		  authorityRecords: (OFDNSResponseRecords)authorityRecords
		 additionalRecords: (OFDNSResponseRecords)additionalRecords
{
	self = [super init];

	@try {
		_domainName = [domainName copy];
		_answerRecords = [answerRecords copy];
		_authorityRecords = [authorityRecords copy];
		_additionalRecords = [additionalRecords copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_domainName release];
	[_answerRecords release];
	[_authorityRecords release];
	[_additionalRecords release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFDNSResponse *response;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFDNSResponse class]])
		return false;

	response = object;

	if (response->_domainName != _domainName &&
	    ![response->_domainName isEqual: _domainName])
		return false;
	if (response->_answerRecords != _answerRecords &&
	    ![response->_answerRecords isEqual: _answerRecords])
		return false;
	if (response->_authorityRecords != _authorityRecords &&
	    ![response->_authorityRecords isEqual: _authorityRecords])
		return false;
	if (response->_additionalRecords != _additionalRecords &&
	    ![response->_additionalRecords isEqual: _additionalRecords])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);
	OFHashAddHash(&hash, _domainName.hash);
	OFHashAddHash(&hash, [_answerRecords hash]);
	OFHashAddHash(&hash, [_authorityRecords hash]);
	OFHashAddHash(&hash, [_additionalRecords hash]);
	OFHashFinalize(&hash);

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
	    @"\tDomain name = %@\n"
	    @"\tAnswer records = %@\n"
	    @"\tAuthority records = %@\n"
	    @"\tAdditional records = %@\n"
	    @">",
	    self.className, _domainName, answerRecords, authorityRecords,
	    additionalRecords];
}
@end
