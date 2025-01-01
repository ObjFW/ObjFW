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

#import "OFString.h"

#define _OFUnicodeUppercaseTableSize 0x1EA
#define _OFUnicodeLowercaseTableSize 0x1EA
#define _OFUnicodeTitlecaseTableSize 0x1EA
#define _OFUnicodeCaseFoldingTableSize 0x1EA

#ifdef __cplusplus
extern "C" {
#endif
extern const OFUnichar *const _Nonnull
    _OFUnicodeUppercaseTable[_OFUnicodeUppercaseTableSize] OF_VISIBILITY_HIDDEN;
extern const OFUnichar *const _Nonnull
    _OFUnicodeLowercaseTable[_OFUnicodeLowercaseTableSize] OF_VISIBILITY_HIDDEN;
extern const OFUnichar *const _Nonnull
    _OFUnicodeTitlecaseTable[_OFUnicodeTitlecaseTableSize] OF_VISIBILITY_HIDDEN;
extern const OFUnichar *const _Nonnull
    _OFUnicodeCaseFoldingTable[_OFUnicodeCaseFoldingTableSize]
    OF_VISIBILITY_HIDDEN;
#ifdef __cplusplus
}
#endif
