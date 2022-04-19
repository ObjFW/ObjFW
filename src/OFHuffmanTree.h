/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#include <stdbool.h>
#include <stdint.h>

#import "macros.h"

#import "OFInvalidFormatException.h"

OF_ASSUME_NONNULL_BEGIN

typedef struct _OFHuffmanTree {
	struct _OFHuffmanTree *_Nullable leaves[2];
	uint16_t value;
} *OFHuffmanTree;

/* Inlined for performance. */
static OF_INLINE bool
OFHuffmanTreeWalk(id _Nullable stream,
    bool (*bitReader)(id _Nullable, uint16_t *_Nonnull, uint8_t),
    OFHuffmanTree _Nonnull *_Nonnull tree, uint16_t *_Nonnull value)
{
	OFHuffmanTree iter = *tree;
	uint16_t bits;

	while (iter->value == 0xFFFF) {
		if OF_UNLIKELY (!bitReader(stream, &bits, 1)) {
			*tree = iter;
			return false;
		}

		if OF_UNLIKELY (iter->leaves[bits] == NULL)
			@throw [OFInvalidFormatException exception];

		iter = iter->leaves[bits];
	}

	*value = iter->value;
	return true;
}

#ifdef __cplusplus
extern "C" {
#endif
extern OFHuffmanTree _Nonnull OFHuffmanTreeNew(uint8_t lengths[_Nonnull],
    uint16_t count);
extern OFHuffmanTree _Nonnull OFHuffmanTreeNewSingle(uint16_t value);
extern void OFHuffmanTreeFree(OFHuffmanTree _Nonnull tree);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
