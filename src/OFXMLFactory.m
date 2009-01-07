/*
 * Copyright (c) 2008 - 2009
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
#import <stdio.h>
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

static inline void
xf_resize_chars(char **str, size_t *len, size_t add, Class class)
{
	char *str2;
	size_t len2;

	if (add > SIZE_MAX - *len)
		@throw [OFOutOfRangeException newWithClass: class];
	len2 = *len + add;

	if ((str2 = realloc(*str, len2)) == NULL) {
		if (*str)
			free(*str);
		*str = NULL;
		@throw [OFNoMemException newWithClass: class
					      andSize: len2];
	}

	*str = str2;
	*len = len2;
}

static inline void
xf_add2chars(char **str, size_t *len, size_t *pos, const char *add, Class class)
{
	size_t add_len;

	add_len = strlen(add);

	xf_resize_chars(str, len, add_len, class);

	memcpy(*str + *pos, add, add_len);
	*pos += add_len;
}

@implementation OFXMLFactory
+ (char*)escapeCString: (const char*)s
{
	char *ret;
	size_t i, j, len, nlen;

	len = nlen = strlen(s);
	if (SIZE_MAX - len < 1)
		@throw [OFOutOfRangeException newWithClass: self];
	nlen++;

	if ((ret = malloc(nlen)) == NULL)
		@throw [OFNoMemException newWithClass: self
					      andSize: nlen];

	for (i = j = 0; i < len; i++) {
		switch (s[i]) {
		case '<':
			xf_add2chars(&ret, &nlen, &j, "&lt;", self);
			break;
		case '>':
			xf_add2chars(&ret, &nlen, &j, "&gt;", self);
			break;
		case '"':
			xf_add2chars(&ret, &nlen, &j, "&quot;", self);
			break;
		case '\'':
			xf_add2chars(&ret, &nlen, &j, "&apos;", self);
			break;
		case '&':
			xf_add2chars(&ret, &nlen, &j, "&amp;", self);
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
	char *arg, *val, *xml, *esc_val = NULL;
	size_t i, len;
	va_list args;

	/* Start of tag */
	len = strlen(name);
	if (SIZE_MAX - len < 3)
		@throw [OFOutOfRangeException newWithClass: self];
	len += 3;

	if ((xml = malloc(len)) == NULL)
		@throw [OFNoMemException newWithClass: self
					      andSize: len];

	i = 0;
	xml[i++] = '<';
	memcpy(xml + i, name, strlen(name));
	i += strlen(name);

	/*
	 * Arguments
	 *
	 * va_start / va_end need to be INSIDE the @try block due to a bug in
	 * gcc 4.0.1. (Only in Apple gcc?)
	 */
	@try {
		va_start(args, data);

		while ((arg = va_arg(args, char*)) != NULL &&
		    (val = va_arg(args, char*)) != NULL) {
			esc_val = NULL;	/* Needed for our @catch */
			esc_val = [self escapeCString: val];

			xf_resize_chars(&xml, &len, 1 + strlen(arg) + 2 +
			    strlen(esc_val) + 1, self);

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
	} @catch (OFException *e) {
		if (esc_val != NULL)
			free(esc_val);
		if (xml != NULL)
			free(xml);

		@throw e;
	}

	/* End of tag */
	if (close) {
		if (data == NULL) {
			xf_resize_chars(&xml, &len, 2 - 1, self);

			xml[i++] = '/';
			xml[i++] = '>';
		} else {
			xf_resize_chars(&xml, &len, 1 + strlen(data) + 2 +
			    strlen(name) + 1 - 1, self);

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
		@throw [OFOutOfRangeException newWithClass: self];
	len++;

	if ((ret = malloc(len)) == NULL)
		@throw [OFNoMemException newWithClass: self
					      andSize: len];

	memcpy(ret, strs[0], len - 1);
	pos = len - 1;

	for (i = 1; strs[i] != NULL; i++)
		xf_add2chars(&ret, &len, &pos, strs[i], self);

	for (i = 0; strs[i] != NULL; i++)
		free(strs[i]);

	ret[pos] = 0;
	return ret;
}
@end
