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

#import "OFGnuTLSX509Name.h"
#import "OFString.h"
#import "OFX509Name+Private.h"

@implementation OFGnuTLSX509Name
- (instancetype)of_initWithDN: (const gnutls_datum_t *)DN
{
	self = [super of_init];

	@try {
		_description = [[OFString alloc]
		    initWithUTF8String: (const char *)DN->data
				length: DN->size];
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
	if (![object isKindOfClass: [OFGnuTLSX509Name class]])
		return false;

	OFGnuTLSX509Name *name = (OFGnuTLSX509Name *)object;
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
