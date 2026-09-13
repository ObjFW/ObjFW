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

#import "OFX509Name.h"

#ifdef __clang__
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wdocumentation-deprecated-sync"
#endif
#include <mbedtls/x509_crt.h>
#include <mbedtls/pk.h>
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_ASSUME_NONNULL_BEGIN

OF_SUBCLASSING_RESTRICTED
@interface OFMbedTLSX509Name: OFX509Name
{
	OFString *_description;
}

- (instancetype)of_initWithDN: (const mbedtls_x509_name *)DN;
@end

OF_ASSUME_NONNULL_END
