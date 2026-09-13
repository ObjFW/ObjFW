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

#import "OFNull.h"
#import "OFData.h"
#import "OFJSONRepresentationPrivate.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@interface OFNull () <OFJSONRepresentationPrivate>
@end

static OFNull *null = nil;

@implementation OFNull
+ (void)initialize
{
	null = [[self alloc] init];
}

+ (OFNull *)null
{
	return null;
}

- (OFString *)description
{
	return @"<null>";
}

- (id)copy
{
	return self;
}

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0 depth: 0];
}

- (OFString *)JSONRepresentationWithOptions:
    (OFJSONRepresentationOptions)options
{
	return [self of_JSONRepresentationWithOptions: options depth: 0];
}

- (OFString *)
    of_JSONRepresentationWithOptions: (OFJSONRepresentationOptions)options
					 depth: (size_t)depth
{
	return @"null";
}

- (OFData *)messagePackRepresentation
{
	uint8_t type = 0xC0;
	return [OFData dataWithItems: &type count: 1];
}

OF_SINGLETON_METHODS
@end
