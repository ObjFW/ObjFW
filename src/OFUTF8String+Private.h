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

#import "OFUTF8String.h"

OF_ASSUME_NONNULL_BEGIN

OF_DIRECT_MEMBERS
@interface OFUTF8String ()
- (instancetype)of_initWithUTF8String: (const char *)UTF8String
			       length: (size_t)UTF8StringLength
			      storage: (char *)storage OF_METHOD_FAMILY(init);
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFUTF8StringCheck(const char *, size_t, size_t *)
    OF_VISIBILITY_HIDDEN;
extern size_t _OFUTF8StringIndexToPosition(const char *, size_t, size_t)
    OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
