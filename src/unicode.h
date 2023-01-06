/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFString.h"

#define OFUnicodeUppercaseTableSize 0x1EA
#define OFUnicodeLowercaseTableSize 0x1EA
#define OFUnicodeTitlecaseTableSize 0x1EA
#define OFUnicodeCaseFoldingTableSize 0x1EA
#define OFUnicodeDecompositionTableSize 0x2FB
#define OFUnicodeDecompositionCompatTableSize 0x2FB

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
extern const char *const _Nullable *const _Nonnull
    OFUnicodeDecompositionTable[OFUnicodeDecompositionTableSize];
extern const char *const _Nullable *const _Nonnull
    OFUnicodeDecompositionCompatTable[OFUnicodeDecompositionCompatTableSize];
#ifdef __cplusplus
}
#endif
