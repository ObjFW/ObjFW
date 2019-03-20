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

#include "config.h"

#include <stdint.h>
#include <stdlib.h>

#import "huffman_tree.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

static struct of_huffman_tree *
newTree(void)
{
	struct of_huffman_tree *tree;

	if ((tree = malloc(sizeof(*tree))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: sizeof(*tree)];

	tree->leaves[0] = tree->leaves[1] = NULL;
	tree->value = 0xFFFF;

	return tree;
}

static void
insertTree(struct of_huffman_tree *tree, uint16_t code, uint8_t length,
    uint16_t value)
{
	while (length > 0) {
		uint8_t bit;

		length--;
		bit = (code & (1 << length)) >> length;

		if (tree->leaves[bit] == NULL)
			tree->leaves[bit] = newTree();

		tree = tree->leaves[bit];
	}

	tree->value = value;
}

struct of_huffman_tree *
of_huffman_tree_construct(uint8_t lengths[], uint16_t count)
{
	struct of_huffman_tree *tree;
	uint16_t *lengthCount = NULL;
	uint16_t code, maxCode = 0, *nextCode = NULL;
	uint_fast8_t maxBit = 0;

	@try {
		for (uint16_t i = 0; i < count; i++) {
			uint_fast8_t length = lengths[i];

			if OF_UNLIKELY (length > maxBit) {
				size_t size = (length + 1) * sizeof(uint16_t);
				uint16_t *new;

				if ((new = realloc(lengthCount, size)) == NULL)
					@throw [OFOutOfMemoryException
					    exceptionWithRequestedSize: size];

				lengthCount = new;

				if ((new = realloc(nextCode, size)) == NULL)
					@throw [OFOutOfMemoryException
					    exceptionWithRequestedSize: size];

				nextCode = new;

				for (uint_fast8_t j = maxBit + 1; j <= length;
				    j++) {
					lengthCount[j] = 0;
					nextCode[j] = 0;
				}

				maxBit = length;
			}

			if (length > 0) {
				lengthCount[length]++;
				maxCode = i;
			}
		}

		code = 0;
		for (size_t i = 1; i <= maxBit; i++) {
			code = (code + lengthCount[i - 1]) << 1;
			nextCode[i] = code;
		}

		tree = newTree();

		for (uint16_t i = 0; i <= maxCode; i++) {
			uint8_t length = lengths[i];

			if (length > 0)
				insertTree(tree, nextCode[length]++, length, i);
		}
	} @finally {
		free(lengthCount);
		free(nextCode);
	}

	return tree;
}

struct of_huffman_tree *
of_huffman_tree_construct_single(uint16_t value)
{
	struct of_huffman_tree *tree = newTree();

	tree->value = value;

	return tree;
}

void
of_huffman_tree_release(struct of_huffman_tree *tree)
{
	for (uint_fast8_t i = 0; i < 2; i++)
		if OF_LIKELY (tree->leaves[i] != NULL)
			of_huffman_tree_release(tree->leaves[i]);

	free(tree);
}
