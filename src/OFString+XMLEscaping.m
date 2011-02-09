/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#import "OFString.h"
#import "OFExceptions.h"

int _OFString_XMLEscaping_reference;

@implementation OFString (XMLEscaping)
- (OFString*)stringByXMLEscaping
{
	char *str_c, *tmp;
	const char *append;
	size_t len, append_len;
	size_t i, j;
	OFString *ret;

	j = 0;
	len = length;

	/*
	 * We can't use allocMemoryWithSize: here as it might be a @"" literal
	 */
	if ((str_c = malloc(len)) == NULL)
		@throw [OFOutOfMemoryException newWithClass: isa
					      requestedSize: len];

	for (i = 0; i < length; i++) {
		switch (string[i]) {
			case '<':
				append = "&lt;";
				append_len = 4;
				break;
			case '>':
				append = "&gt;";
				append_len = 4;
				break;
			case '"':
				append = "&quot;";
				append_len = 6;
				break;
			case '\'':
				append = "&apos;";
				append_len = 6;
				break;
			case '&':
				append = "&amp;";
				append_len = 5;
				break;
			default:
				append = NULL;
				append_len = 0;
		}

		if (append != NULL) {
			if ((tmp = realloc(str_c, len + append_len)) == NULL) {
				free(str_c);
				@throw [OFOutOfMemoryException
				     newWithClass: isa
				    requestedSize: len + append_len];
			}
			str_c = tmp;
			len += append_len - 1;

			memcpy(str_c + j, append, append_len);
			j += append_len;
		} else
			str_c[j++] = string[i];
	}

	assert(j == len);

	@try {
		ret = [OFString stringWithCString: str_c
					   length: len];
	} @finally {
		free(str_c);
	}
	return ret;
}
@end
