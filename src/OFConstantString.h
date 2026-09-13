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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#if !defined(OF_CONSTANT_STRING_M) && \
    defined(OF_APPLE_RUNTIME) && !defined(__OBJC2__)
# ifdef __cplusplus
extern "C" {
# endif
extern void *_OFConstantStringClassReference;
# ifdef __cplusplus
}
# endif
#endif

/**
 * @class OFConstantString OFConstantString.h ObjFW/ObjFW.h
 *
 * @brief A class for storing constant strings using the `@""` literal.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFConstantString: OFString
{
	char *_cString;
	unsigned int _cStringLength;
}
@end

OF_ASSUME_NONNULL_END
