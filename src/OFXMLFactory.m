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

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <limits.h>

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
resize(char **str, size_t *len, size_t add, Class class)
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
append(char **str, size_t *len, size_t *pos, const char *add, Class class)
{
	size_t add_len;

	add_len = strlen(add);

	resize(str, len, add_len, class);

	memcpy(*str + *pos, add, add_len);
	*pos += add_len;
}

@implementation OFXMLFactory
+ (char*)escapeCString: (const char*)s
{
	char *ret;
	size_t i, len;

	len = strlen(s);
	if (SIZE_MAX - len < 1)
		@throw [OFOutOfRangeException newWithClass: self];

	len++;
	if ((ret = malloc(len)) == NULL)
		@throw [OFNoMemException newWithClass: self
					      andSize: len];

	@try {
		for (i = 0; *s; s++) {
			switch (*s) {
				case '<':
					append(&ret, &len, &i, "&lt;", self);
					break;
				case '>':
					append(&ret, &len, &i, "&gt;", self);
					break;
				case '"':
					append(&ret, &len, &i, "&quot;", self);
					break;
				case '\'':
					append(&ret, &len, &i, "&apos;", self);
					break;
				case '&':
					append(&ret, &len, &i, "&amp;", self);
					break;
				default:
					ret[i++] = *s;
					break;
			}
		}
	} @catch (OFException *e) {
		free(ret);
		@throw e;
	}

	ret[i] = 0;
	return ret;
}

+ (char*)createStanza: (const char*)name, ...
{
	char *ret;
	va_list attrs;

	va_start(attrs, name);
	ret = [self createStanza: name
		    withCloseTag: YES
		   andAttributes: attrs
			 andData: NULL];
	va_end(attrs);

	return ret;
}

+ (char*)createStanza: (const char*)name
	     withData: (const char*)data, ...
{
	char *ret;
	va_list attrs;

	va_start(attrs, data);
	ret = [self createStanza: name
		    withCloseTag: YES
		   andAttributes: attrs
			 andData: data];
	va_end(attrs);

	return ret;
}

+ (char*)createStanza: (const char*)name
	 withCloseTag: (BOOL)close
	      andData: (const char*)data, ...
{
	char *ret;
	va_list attrs;

	va_start(attrs, data);
	ret = [self createStanza: name
		    withCloseTag: close
		   andAttributes: attrs
			 andData: data];
	va_end(attrs);

	return ret;
}

+ (char*)createStanza: (const char*)name
	 withCloseTag: (BOOL)close
	andAttributes: (va_list)attrs
	      andData: (const char*)data
{
	char *arg, *val, *xml, *esc_val = NULL;
	size_t i, len;

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

	@try {
		while ((arg = va_arg(attrs, char*)) != NULL &&
		    (val = va_arg(attrs, char*)) != NULL) {
			esc_val = NULL;	/* Needed for our @catch */
			esc_val = [self escapeCString: val];

			resize(&xml, &len, 1 + strlen(arg) + 2 +
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

		/* End of tag */
		if (close) {
			if (data == NULL) {
				resize(&xml, &len, 2 - 1, self);

				xml[i++] = '/';
				xml[i++] = '>';
			} else {
				resize(&xml, &len, 1 + strlen(data) + 2 +
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
	} @catch (OFException *e) {
		if (esc_val != NULL)
			free(esc_val);
		free(xml);
		@throw e;
	}

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

	@try {
		for (i = 1; strs[i] != NULL; i++)
			append(&ret, &len, &pos, strs[i], self);

		for (i = 0; strs[i] != NULL; i++)
			free(strs[i]);
	} @catch (OFException *e) {
		free(ret);
		@throw e;
	}

	ret[pos] = 0;
	return ret;
}
@end
