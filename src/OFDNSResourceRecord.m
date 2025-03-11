/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFDNSResourceRecord.h"
#import "OFArray.h"
#import "OFData.h"

#import "OFInvalidFormatException.h"

OFString *
OFDNSClassName(OFDNSClass DNSClass)
{
	switch (DNSClass) {
	case OFDNSClassIN:
		return @"IN";
	case OFDNSClassAny:
		return @"any";
	default:
		return [OFString stringWithFormat: @"%u", DNSClass];
	}
}

OFString *
OFDNSRecordTypeName(OFDNSRecordType recordType)
{
	switch (recordType) {
	case OFDNSRecordTypeA:
		return @"A";
	case OFDNSRecordTypeNS:
		return @"NS";
	case OFDNSRecordTypeCNAME:
		return @"CNAME";
	case OFDNSRecordTypeSOA:
		return @"SOA";
	case OFDNSRecordTypePTR:
		return @"PTR";
	case OFDNSRecordTypeHINFO:
		return @"HINFO";
	case OFDNSRecordTypeMX:
		return @"MX";
	case OFDNSRecordTypeTXT:
		return @"TXT";
	case OFDNSRecordTypeRP:
		return @"RP";
	case OFDNSRecordTypeAAAA:
		return @"AAAA";
	case OFDNSRecordTypeLOC:
		return @"LOC";
	case OFDNSRecordTypeSRV:
		return @"SRV";
	case OFDNSRecordTypeAll:
		return @"all";
	case OFDNSRecordTypeURI:
		return @"URI";
	default:
		return [OFString stringWithFormat: @"%u", recordType];
	}
}

OFDNSClass
OFDNSClassParseName(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSClass DNSClass;

	string = string.uppercaseString;

	if ([string isEqual: @"IN"])
		DNSClass = OFDNSClassIN;
	else
		DNSClass = [string intValueWithBase: 0];

	objc_autoreleasePoolPop(pool);

	return DNSClass;
}

OFDNSRecordType
OFDNSRecordTypeParseName(OFString *string)
{
	void *pool = objc_autoreleasePoolPush();
	OFDNSRecordType recordType;

	string = string.uppercaseString;

	if ([string isEqual: @"A"])
		recordType = OFDNSRecordTypeA;
	else if ([string isEqual: @"NS"])
		recordType = OFDNSRecordTypeNS;
	else if ([string isEqual: @"CNAME"])
		recordType = OFDNSRecordTypeCNAME;
	else if ([string isEqual: @"SOA"])
		recordType = OFDNSRecordTypeSOA;
	else if ([string isEqual: @"PTR"])
		recordType = OFDNSRecordTypePTR;
	else if ([string isEqual: @"HINFO"])
		recordType = OFDNSRecordTypeHINFO;
	else if ([string isEqual: @"MX"])
		recordType = OFDNSRecordTypeMX;
	else if ([string isEqual: @"TXT"])
		recordType = OFDNSRecordTypeTXT;
	else if ([string isEqual: @"RP"])
		recordType = OFDNSRecordTypeRP;
	else if ([string isEqual: @"AAAA"])
		recordType = OFDNSRecordTypeAAAA;
	else if ([string isEqual: @"LOC"])
		recordType = OFDNSRecordTypeLOC;
	else if ([string isEqual: @"SRV"])
		recordType = OFDNSRecordTypeSRV;
	else if ([string isEqual: @"ALL"])
		recordType = OFDNSRecordTypeAll;
	else if ([string isEqual: @"URI"])
		recordType = OFDNSRecordTypeURI;
	else
		recordType = [string intValueWithBase: 0];

	objc_autoreleasePoolPop(pool);

	return recordType;
}

@implementation OFDNSResourceRecord
@synthesize name = _name, DNSClass = _DNSClass, recordType = _recordType;
@synthesize TTL = _TTL;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	self = [super init];

	@try {
		_name = [name copy];
		_DNSClass = DNSClass;
		_recordType = recordType;
		_TTL = TTL;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tType = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass),
	    OFDNSRecordTypeName(_recordType), _TTL];
}
@end
