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

#include "config.h"

#import "OFMbedTLSX509Name.h"
#import "OFData.h"
#import "OFString.h"
#import "OFX509Name+Private.h"

#import "OFInvalidFormatException.h"

@implementation OFMbedTLSX509Name
- (instancetype)of_initWithDN: (const mbedtls_x509_name *)DN
{
	self = [super of_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		OFMutableData *data = [OFMutableData dataWithCapacity: 128];
		[data increaseCountBy: 128];

		int ret;
		while ((ret = mbedtls_x509_dn_gets(data.mutableItems,
		    data.count, DN)) == MBEDTLS_ERR_X509_BUFFER_TOO_SMALL)
			[data increaseCountBy: data.count];

		if (ret < 0)
			@throw [OFInvalidFormatException exception];

		_description = [[OFString alloc] initWithUTF8String: data.items
							     length: ret];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_description);

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	if (![object isKindOfClass: [OFMbedTLSX509Name class]])
		return false;

	OFMbedTLSX509Name *name = (OFMbedTLSX509Name *)object;
	return [name->_description isEqual: _description];
}

- (unsigned long)hash
{
	return _description.hash;
}

- (OFString *)description
{
	return _description;
}
@end
