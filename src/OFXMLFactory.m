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

#import <stdarg.h>
#import <stddef.h>
#import <stdlib.h>
#import <string.h>

#import "OFXMLFactory.h"
#import "OFExceptions.h"

/*
 * We don't use OFString in this file for performance reasons!
 *
 * We already have a clue about how big the resulting string will get, so we
 * can prealloc and only resize when really necessary - OFString would always
 * resize when we append, which would be slow here.
 */

static inline BOOL
xmlfactory_resize(char **str, size_t *len, size_t add)
{
	char *str2;
	size_t len2;

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
xmlfactory_add2str(char **str, size_t *len, size_t *pos, const char *add)
{
	size_t add_len;

	add_len = strlen(add);

	if (!xmlfactory_resize(str, len, add_len))
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

	if ((ret = malloc(len + 1)) == NULL) {
		[[OFNoMemException newWithObject: nil
					 andSize: len + 1] raise];
		return NULL;
	}

	for (i = j = 0; i < len; i++) {
		switch (s[i]) {
		case '<':
			if (!xmlfactory_add2str(&ret, &nlen, &j, "&lt;")) {
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 4]
				    raise];
				return NULL;
			}
			break;
		case '>':
			if (!xmlfactory_add2str(&ret, &nlen, &j, "&gt;")) {
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 4]
				    raise];
				return NULL;
			}
			break;
		case '"':
			if (!xmlfactory_add2str(&ret, &nlen, &j, "&quot;")) {
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 6]
				    raise];
				return NULL;
			}
			break;
		case '\'':
			if (!xmlfactory_add2str(&ret, &nlen, &j, "&apos;")) {
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 6]
				    raise];
				return NULL;
			}
			break;
		case '&':
			if (!xmlfactory_add2str(&ret, &nlen, &j, "&amp;")) {
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 5]
				    raise];
				return NULL;
			}
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
	     andCData: (const char*)cdata, ...
{
	char *arg, *val, *xml;
	size_t i, len;
	va_list args;

	/* Start of tag */
	len = strlen(name) + 3;
	if ((xml = malloc(len)) == NULL) {
		[[OFNoMemException newWithObject: nil
					 andSize: len] raise];
		return NULL;
	}

	i = 0;
	xml[i++] = '<';
	memcpy(xml + i, name, strlen(name));
	i += strlen(name);

	/* Arguments */
	va_start(args, cdata);
	while ((arg = va_arg(args, char*)) != NULL &&
	    (val = va_arg(args, char*)) != NULL) {
		char *esc_val;

		if ((esc_val = [OFXMLFactory escapeCString: val]) == NULL) {
			/*
			 * escapeCString already throws an exception,
			 * no need to throw a second one here.
			 */
			free(xml);
			return NULL;
		}

		if (!xmlfactory_resize(&xml, &len, 1 + strlen(arg) + 2 +
		    strlen(esc_val) + 1)) {
			free(esc_val);
			[[OFNoMemException newWithObject: nil
						 andSize: len + 1 +
							  strlen(arg) + 2 +
							  strlen(esc_val) + 1]
			    raise];
			return NULL;
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
		if (cdata == NULL) {
			if (!xmlfactory_resize(&xml, &len, 2 - 1)) {
				[[OFNoMemException newWithObject: nil
							 andSize: len + 2 - 1]
				    raise];
				return NULL;
			}
	
			xml[i++] = '/';
			xml[i++] = '>';
		} else {
			if (!xmlfactory_resize(&xml, &len, 1 + strlen(cdata) +
			    2 + strlen(name) + 1 - 1)) {
				[[OFNoMemException newWithObject: nil
							 andSize: len + 1 +
								  strlen(
								      cdata) +
								  2 +
								  strlen(name) +
								  1 - 1]
				    raise];
				return NULL;
			}
	
			xml[i++] = '>';
			memcpy(xml + i, cdata, strlen(cdata));
			i += strlen(cdata);
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

+ (char*)concatAndFreeCStrings: (char **)strs
{
	char *ret;
	size_t i, len, pos;

	if (strs[0] == NULL)
		return NULL;

	len = strlen(*strs) + 1;
	
	if ((ret = malloc(len)) == NULL) {
		[[OFNoMemException newWithObject: nil
					 andSize: len] raise];
		return NULL;
	}

	memcpy(ret, strs[0], len - 1);
	pos = len - 1;

	for (i = 1; strs[i] != NULL; i++) {
		if (!xmlfactory_add2str(&ret, &len, &pos, strs[i])) {
			free(ret);
			[[OFNoMemException newWithObject: nil
						 andSize: len + strlen(strs[i])]
			    raise];
			return NULL;
		}
	}

	for (i = 0; strs[i] != NULL; i++)
		free(strs[i]);

	ret[pos] = 0;
	return ret;
}
@end
