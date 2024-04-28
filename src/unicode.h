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

#import "OFString.h"

#define OFUnicodeUppercaseTableSize 0x1EA
#define OFUnicodeLowercaseTableSize 0x1EA
#define OFUnicodeTitlecaseTableSize 0x1EA
#define OFUnicodeCaseFoldingTableSize 0x1EA

#ifdef __cplusplus
extern "C" {
#endif
extern const OFUnichar *const _Nonnull
    OFUnicodeUppercaseTable[OFUnicodeUppercaseTableSize];
extern const OFUnichar *const _Nonnull
    OFUnicodeLowercaseTable[OFUnicodeLowercaseTableSize];
extern const OFUnichar *const _Nonnull
    OFUnicodeTitlecaseTable[OFUnicodeTitlecaseTableSize];
extern const OFUnichar *const _Nonnull
    OFUnicodeCaseFoldingTable[OFUnicodeCaseFoldingTableSize];
#ifdef __cplusplus
}
#endif
