/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

struct of_huffman_tree {
	struct of_huffman_tree *_Nullable leaves[2];
	uint16_t value;
};

#ifdef __cplusplus
extern "C" {
#endif
extern struct of_huffman_tree *_Nonnull of_huffman_tree_construct(
    uint8_t lengths[_Nonnull], uint16_t count);
extern struct of_huffman_tree *_Nonnull of_huffman_tree_construct_single(
    uint16_t value);
extern bool of_huffman_tree_walk(OFStream *_Nullable stream,
    bool (*bitReader)(OFStream *_Nullable, uint16_t *_Nonnull, uint8_t),
    struct of_huffman_tree *_Nonnull *_Nonnull tree, uint16_t *_Nonnull value);
extern void of_huffman_tree_release(struct of_huffman_tree *_Nonnull tree);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
