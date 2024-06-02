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

#import "HIDGameController.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFSet.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "HIDEvdevGameController.h"
#endif

@implementation HIDGameController
@dynamic name, unmappedMapping;

+ (OFArray OF_GENERIC(HIDGameController *) *)controllers
{
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	return [HIDEvdevGameController controllers];
#else
	return [OFArray array];
#endif
}

- (instancetype)init
{
	if ([self isMemberOfClass: [HIDGameController class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (OFNumber *)vendorID
{
	return nil;
}

- (OFNumber *)productID
{
	return nil;
}

- (void)retrieveState
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
	if (self.vendorID != nil && self.productID != nil)
		return [OFString stringWithFormat:
		    @"<%@: %@ [%04X:%04X]>",
		    self.class, self.name, self.vendorID.unsignedShortValue,
		    self.productID.unsignedShortValue];
	else
		return [OFString stringWithFormat: @"<%@: %@>",
						   self.class, self.name];
}
@end

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "HIDEvdevGameController.m"
#endif
