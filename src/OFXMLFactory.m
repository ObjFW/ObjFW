/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdarg.h>
#import <stdlib.h>
#import <string.h>
#import <limits.h>

#import "OFXMLFactory.h"
#import "OFExceptions.h"
#import "OFMacros.h"

/*
 * We don't use OFString in this file for performance reasons!
 *
 * We already have a clue about how big the resulting string will get, so we
 * can prealloc and only resize when really necessary - OFString would always
 * resize when we append, which would be slow here.
 */

static inline BOOL
xf_resize_chars(char **str, size_t *len, size_t add)
{
	char *str2;
	size_t len2;

	if (add > SIZE_MAX - *len)
		@throw [OFOutOfRangeException newWithObject: nil];
	len2 = *len + add;

	if ((str2 = realloc(*str, len2)) == NULL) {
		if (*str)
			free(*str);
		*str = NULL;
		return NO;
	}

	*str = str2;
	*len = len2;

	return YES;
}

static inline BOOL
xf_add2chars(char **str, size_t *len, size_t *pos, const char *add)
{
	size_t add_len;

	add_len = strlen(add);

	if (!xf_resize_chars(str, len, add_len))
		return NO;

	memcpy(*str + *pos, add, add_len);
	*pos += add_len;

	return YES;
}

@implementation OFXMLFactory
+ (char*)escapeCString: (const char*)s
{
	char *ret;
	size_t i, j, len, nlen;

	len = nlen = strlen(s);
	if (SIZE_MAX - len < 1)
		@throw [OFOutOfRangeException newWithObject: nil];
	nlen++;

	if ((ret = malloc(nlen)) == NULL)
		@throw [OFNoMemException newWithObject: nil
					       andSize: nlen];

	for (i = j = 0; i < len; i++) {
		switch (s[i]) {
		case '<':
			if (OF_UNLIKELY(!xf_add2chars(&ret, &nlen, &j, "&lt;")))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: nlen + 4];
			break;
		case '>':
			if (OF_UNLIKELY(!xf_add2chars(&ret, &nlen, &j, "&gt;")))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: nlen + 4];
			break;
		case '"':
			if (OF_UNLIKELY(!xf_add2chars(&ret, &nlen, &j,
			    "&quot;")))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: nlen + 6];
			break;
		case '\'':
			if (OF_UNLIKELY(!xf_add2chars(&ret, &nlen, &j,
			    "&apos;")))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: nlen + 6];
			break;
		case '&':
			if (OF_UNLIKELY(!xf_add2chars(&ret, &nlen, &j,
			    "&amp;")))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: nlen + 5];
			break;
		default:
			ret[j++] = s[i];
			break;
		}
	}

	ret[j] = 0;
	return ret;
}

+ (char*)createStanza: (const char*)name
	 withCloseTag: (BOOL)close
	      andData: (const char*)data, ...
{
	char *arg, *val, *xml;
	size_t i, len;
	va_list args;

	/* Start of tag */
	len = strlen(name);
	if (SIZE_MAX - len < 3)
		@throw [OFOutOfRangeException newWithObject: nil];
	len += 3;

	if ((xml = malloc(len)) == NULL)
		@throw [OFNoMemException newWithObject: nil
					       andSize: len];

	i = 0;
	xml[i++] = '<';
	memcpy(xml + i, name, strlen(name));
	i += strlen(name);

	/* Arguments */
	va_start(args, data);
	while ((arg = va_arg(args, char*)) != NULL &&
	    (val = va_arg(args, char*)) != NULL) {
		char *esc_val;

		if (OF_UNLIKELY((esc_val =
		    [OFXMLFactory escapeCString: val]) == NULL)) {
			/*
			 * escapeCString already throws an exception,
			 * no need to throw a second one here.
			 */
			free(xml);
			return NULL;
		}

		if (OF_UNLIKELY(!xf_resize_chars(&xml, &len, 1 + strlen(arg) +
		    2 + strlen(esc_val) + 1))) {
			free(esc_val);
			@throw [OFNoMemException
			    newWithObject: nil
				  andSize: len + 1 + strlen(arg) + 2 +
					   strlen(esc_val) + 1];
		}

		xml[i++] = ' ';
		memcpy(xml + i, arg, strlen(arg));
		i += strlen(arg);
		xml[i++] = '=';
		xml[i++] = '\'';
		memcpy(xml + i, esc_val, strlen(esc_val));
		i += strlen(esc_val);
		xml[i++] = '\'';

		free(esc_val);
	}
	va_end(args);

	/* End of tag */
	if (close) {
		if (data == NULL) {
			if (!xf_resize_chars(&xml, &len, 2 - 1))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: len + 2 - 1];

			xml[i++] = '/';
			xml[i++] = '>';
		} else {
			if (!xf_resize_chars(&xml, &len, 1 + strlen(data) +
			    2 + strlen(name) + 1 - 1))
				@throw [OFNoMemException
				    newWithObject: nil
					  andSize: len + 1 + strlen(data) + 2 +
						   strlen(name) + 1 - 1];

			xml[i++] = '>';
			memcpy(xml + i, data, strlen(data));
			i += strlen(data);
			xml[i++] = '<';
			xml[i++] = '/';
			memcpy(xml + i, name, strlen(name));
			i += strlen(name);
			xml[i++] = '>';
		}
	} else
		xml[i++] = '>';

	xml[i] = 0;
	return xml;
}

+ (char*)concatAndFreeCStrings: (char**)strs
{
	char *ret;
	size_t i, len, pos;

	if (strs[0] == NULL)
		return NULL;

	len = strlen(*strs);
	if (SIZE_MAX - len < 1)
		@throw [OFOutOfRangeException newWithObject: nil];
	len++;

	if ((ret = malloc(len)) == NULL)
		@throw [OFNoMemException newWithObject: nil
					       andSize: len];

	memcpy(ret, strs[0], len - 1);
	pos = len - 1;

	for (i = 1; strs[i] != NULL; i++) {
		if (OF_UNLIKELY(!xf_add2chars(&ret, &len, &pos, strs[i]))) {
			free(ret);
			@throw [OFNoMemException
			    newWithObject: nil
				  andSize: len + strlen(strs[i])];
		}
	}

	for (i = 0; strs[i] != NULL; i++)
		free(strs[i]);

	ret[pos] = 0;
	return ret;
}
@end
