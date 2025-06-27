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
_OFHuffmanTreeWalk(id _Nullable stream,
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
extern OFHuffmanTree _Nonnull _OFHuffmanTreeNew(uint8_t lengths[_Nonnull],
    uint16_t count) OF_VISIBILITY_INTERNAL;
extern OFHuffmanTree _Nonnull _OFHuffmanTreeNewSingle(uint16_t value)
    OF_VISIBILITY_INTERNAL;
extern void _OFHuffmanTreeFree(OFHuffmanTree _Nonnull tree)
    OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
