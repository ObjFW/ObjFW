/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFTXTDNSResourceRecord.h"
#import "OFArray.h"
#import "OFData.h"

@implementation OFTXTDNSResourceRecord
@synthesize textStrings = _textStrings;

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		  recordType: (OFDNSRecordType)recordType
			 TTL: (uint32_t)TTL
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		    DNSClass: (OFDNSClass)DNSClass
		 textStrings: (OFArray OF_GENERIC(OFData *) *)textStrings
			 TTL: (uint32_t)TTL
{
	self = [super initWithName: name
			  DNSClass: DNSClass
			recordType: OFDNSRecordTypeTXT
			       TTL: TTL];

	@try {
		_textStrings = [textStrings copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_textStrings release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFTXTDNSResourceRecord *record;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFTXTDNSResourceRecord class]])
		return false;

	record = object;

	if (record->_name != _name && ![record->_name isEqual: _name])
		return false;

	if (record->_DNSClass != _DNSClass)
		return false;

	if (record->_recordType != _recordType)
		return false;

	if (record->_textStrings != _textStrings &&
	    ![record->_textStrings isEqual: _textStrings])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddByte(&hash, _DNSClass >> 8);
	OFHashAddByte(&hash, _DNSClass);
	OFHashAddByte(&hash, _recordType >> 8);
	OFHashAddByte(&hash, _recordType);
	OFHashAddHash(&hash, _textStrings.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableString *text = [OFMutableString string];
	bool first = true;
	OFString *ret;

	for (OFData *string in _textStrings) {
		const unsigned char *stringItems = string.items;
		size_t stringCount = string.count;

		if (first) {
			first = false;
			[text appendString: @"\""];
		} else
			[text appendString: @" \""];

		for (size_t i = 0; i < stringCount; i++) {
			if (stringItems[i] == '\\')
				[text appendString: @"\\\\"];
			else if (stringItems[i] == '"')
				[text appendString: @"\\\""];
			else if (stringItems[i] < 0x20)
				[text appendFormat: @"\\x%02X", stringItems[i]];
			else if (stringItems[i] < 0x7F)
				[text appendFormat: @"%c", stringItems[i]];
			else
				[text appendFormat: @"\\x%02X", stringItems[i]];
		}

		[text appendString: @"\""];
	}

	ret = [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tName = %@\n"
	    @"\tClass = %@\n"
	    @"\tText strings = %@\n"
	    @"\tTTL = %" PRIu32 "\n"
	    @">",
	    self.className, _name, OFDNSClassName(_DNSClass), text, _TTL];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
