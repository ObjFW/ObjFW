/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

struct of_huffman_tree {
	struct of_huffman_tree *_Nullable leaves[2];
	uint16_t value;
};

static OF_INLINE bool
of_huffman_tree_walk(id _Nullable stream,
    bool (*bitReader)(id _Nullable, uint16_t *_Nonnull, uint8_t),
    struct of_huffman_tree *_Nonnull *_Nonnull tree, uint16_t *_Nonnull value)
{
	struct of_huffman_tree *iter = *tree;
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
extern struct of_huffman_tree *_Nonnull of_huffman_tree_construct(
    uint8_t lengths[_Nonnull], uint16_t count);
extern struct of_huffman_tree *_Nonnull of_huffman_tree_construct_single(
    uint16_t value);
extern void of_huffman_tree_release(struct of_huffman_tree *_Nonnull tree);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
