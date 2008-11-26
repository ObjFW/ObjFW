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
xf_resize_chars(char **str, size_t *len, size_t add)
{
	char *str2;
	size_t len2;

	/* FIXME: Check for overflows on add */

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
xf_resize_wchars(wchar_t **str, size_t *len, size_t add)
{
	wchar_t *str2;
	size_t len2;

	/* FIXME: Check for overflows on add and multiply */

	len2 = *len + add;
	
	if ((str2 = realloc(*str, len2 * sizeof(wchar_t))) == NULL) {
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

static inline BOOL
xf_add2wchars(wchar_t **str, size_t *len, size_t *pos, const wchar_t *add)
{
	size_t add_len;

	add_len = wcslen(add);

	if (!xf_resize_wchars(str, len, add_len))
		return NO;

	wmemcpy(*str + *pos, add, add_len);
	*pos += add_len;

	return YES;
}

@implementation OFXMLFactory
+ (char*)escapeCString: (const char*)s
{
	char *ret;
	size_t i, j, len, nlen;

	len = nlen = strlen(s);

	if ((ret = malloc(len + 1)) == NULL)
		[[OFNoMemException newWithObject: nil
					 andSize: len + 1] raise];

	for (i = j = 0; i < len; i++) {
		switch (s[i]) {
		case '<':
			if (!xf_add2chars(&ret, &nlen, &j, "&lt;"))
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 4]
				    raise];
			break;
		case '>':
			if (!xf_add2chars(&ret, &nlen, &j, "&gt;"))
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 4]
				    raise];
			break;
		case '"':
			if (!xf_add2chars(&ret, &nlen, &j, "&quot;"))
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 6]
				    raise];
			break;
		case '\'':
			if (!xf_add2chars(&ret, &nlen, &j, "&apos;"))
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 6]
				    raise];
			break;
		case '&':
			if (!xf_add2chars(&ret, &nlen, &j, "&amp;"))
				[[OFNoMemException newWithObject: nil
							 andSize: nlen + 5]
				    raise];
			break;
		default:
			ret[j++] = s[i];
			break;
		}
	}

	ret[j] = 0;
	return ret;
}

+ (wchar_t*)escapeWideCString: (const wchar_t*)s
{
	wchar_t *ret;
	size_t i, j, len, nlen;

	len = nlen = wcslen(s);

	/* FIXME: Check for overflow in multiply */
	if ((ret = malloc((len + 1) * sizeof(wchar_t))) == NULL)
		[[OFNoMemException newWithObject: nil
					 andSize: (len + 1) * sizeof(wchar_t)]
		     raise];

	for (i = j = 0; i < len; i++) {
		switch (s[i]) {
		case L'<':
			if (!xf_add2wchars(&ret, &nlen, &j, L"&lt;"))
				[[OFNoMemException newWithObject: nil
							 andSize: (nlen + 4) *
								  sizeof(
								  wchar_t)]
				    raise];
			break;
		case L'>':
			if (!xf_add2wchars(&ret, &nlen, &j, L"&gt;"))
				[[OFNoMemException newWithObject: nil
							 andSize: (nlen + 4) *
								  sizeof(
								  wchar_t)]
				    raise];
			break;
		case L'"':
			if (!xf_add2wchars(&ret, &nlen, &j, L"&quot;"))
				[[OFNoMemException newWithObject: nil
							 andSize: (nlen + 6) *
								  sizeof(
								  wchar_t)]
				    raise];
			break;
		case L'\'':
			if (!xf_add2wchars(&ret, &nlen, &j, L"&apos;"))
				[[OFNoMemException newWithObject: nil
							 andSize: (nlen + 6) *
								  sizeof(
								  wchar_t)]
				    raise];
			break;
		case L'&':
			if (!xf_add2wchars(&ret, &nlen, &j, L"&amp;"))
				[[OFNoMemException newWithObject: nil
							 andSize: (nlen + 5) *
								  sizeof(
								  wchar_t)]
				    raise];
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
	len = strlen(name) + 3;
	if ((xml = malloc(len)) == NULL)
		[[OFNoMemException newWithObject: nil
					 andSize: len] raise];

	i = 0;
	xml[i++] = '<';
	memcpy(xml + i, name, strlen(name));
	i += strlen(name);

	/* Arguments */
	va_start(args, data);
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

		if (!xf_resize_chars(&xml, &len, 1 + strlen(arg) + 2 +
		    strlen(esc_val) + 1)) {
			free(esc_val);
			[[OFNoMemException newWithObject: nil
						 andSize: len + 1 +
							  strlen(arg) + 2 +
							  strlen(esc_val) + 1]
			    raise];
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
				[[OFNoMemException newWithObject: nil
							 andSize: len + 2 - 1]
				    raise];
	
			xml[i++] = '/';
			xml[i++] = '>';
		} else {
			if (!xf_resize_chars(&xml, &len, 1 + strlen(data) +
			    2 + strlen(name) + 1 - 1))
				[[OFNoMemException newWithObject: nil
							 andSize: len + 1 +
								  strlen(data) +
								  2 +
								  strlen(name) +
								  1 - 1]
				    raise];
	
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

+ (wchar_t*)createWideStanza: (const wchar_t*)name
		withCloseTag: (BOOL)close
		     andData: (const wchar_t*)data, ...
{
	wchar_t *arg, *val, *xml;
	size_t i, len;
	va_list args;

	/* Start of tag */
	len = wcslen(name) + 3;
	/* TODO: Check for multiply overflow */
	if ((xml = malloc(len * sizeof(wchar_t*))) == NULL)
		[[OFNoMemException newWithObject: nil
					 andSize: len * sizeof(wchar_t)] raise];

	i = 0;
	xml[i++] = L'<';
	wmemcpy(xml + i, name, wcslen(name));
	i += wcslen(name);

	/* Arguments */
	va_start(args, data);
	while ((arg = va_arg(args, wchar_t*)) != NULL &&
	    (val = va_arg(args, wchar_t*)) != NULL) {
		wchar_t *esc_val;

		if ((esc_val = [OFXMLFactory escapeWideCString: val]) == NULL) {
			/*
			 * escapeWideCString already throws an exception,
			 * no need to throw a second one here.
			 */
			free(xml);
			return NULL;
		}

		if (!xf_resize_wchars(&xml, &len, 1 + wcslen(arg) + 2 +
		    wcslen(esc_val) + 1)) {
			free(esc_val);
			[[OFNoMemException newWithObject: nil
						 andSize: (len + 1 +
							  wcslen(arg) + 2 +
							  wcslen(esc_val) + 1) *
							  sizeof(wchar_t)]
			    raise];
		}

		xml[i++] = L' ';
		wmemcpy(xml + i, arg, wcslen(arg));
		i += wcslen(arg);
		xml[i++] = L'=';
		xml[i++] = L'\'';
		wmemcpy(xml + i, esc_val, wcslen(esc_val));
		i += wcslen(esc_val);
		xml[i++] = L'\'';

		free(esc_val);
	}
	va_end(args);

	/* End of tag */
	if (close) {
		if (data == NULL) {
			if (!xf_resize_wchars(&xml, &len, 2 - 1))
				[[OFNoMemException newWithObject: nil
							 andSize: (len + 2
								  - 1) * sizeof(
								  wchar_t)]
				    raise];
	
			xml[i++] = L'/';
			xml[i++] = L'>';
		} else {
			if (!xf_resize_wchars(&xml, &len, 1 + wcslen(data) +
			    2 + wcslen(name) + 1 - 1))
				[[OFNoMemException newWithObject: nil
							 andSize: (len + 1 +
								  wcslen(data) +
								  2 +
								  wcslen(name) +
								  1 -
								  1) * sizeof(
								  wchar_t)]
				    raise];
	
			xml[i++] = L'>';
			wmemcpy(xml + i, data, wcslen(data));
			i += wcslen(data);
			xml[i++] = L'<';
			xml[i++] = L'/';
			wmemcpy(xml + i, name, wcslen(name));
			i += wcslen(name);
			xml[i++] = L'>';
		}
	} else
		xml[i++] = L'>';

	xml[i] = 0;
	return xml;
}

+ (char*)concatAndFreeCStrings: (char**)strs
{
	char *ret;
	size_t i, len, pos;

	if (strs[0] == NULL)
		return NULL;

	len = strlen(*strs) + 1;
	
	if ((ret = malloc(len)) == NULL)
		[[OFNoMemException newWithObject: nil
					 andSize: len] raise];

	memcpy(ret, strs[0], len - 1);
	pos = len - 1;

	for (i = 1; strs[i] != NULL; i++) {
		if (!xf_add2chars(&ret, &len, &pos, strs[i])) {
			free(ret);
			[[OFNoMemException newWithObject: nil
						 andSize: len + strlen(strs[i])]
			    raise];
		}
	}

	for (i = 0; strs[i] != NULL; i++)
		free(strs[i]);

	ret[pos] = 0;
	return ret;
}

+ (wchar_t*)concatAndFreeWideCStrings: (wchar_t**)strs
{
	wchar_t *ret;
	size_t i, len, pos;

	if (strs[0] == NULL)
		return NULL;

	len = wcslen(*strs) + 1;
	
	/* FIXME: Check for overflow on multiply */
	if ((ret = malloc(len * sizeof(wchar_t))) == NULL)
		[[OFNoMemException newWithObject: nil
					 andSize: len * sizeof(wchar_t)] raise];

	wmemcpy(ret, strs[0], len - 1);
	pos = len - 1;

	for (i = 1; strs[i] != NULL; i++) {
		if (!xf_add2wchars(&ret, &len, &pos, strs[i])) {
			free(ret);
			[[OFNoMemException newWithObject: nil
						 andSize: (wcslen(strs[i]) +
							  len) * sizeof(
							  wchar_t)]
			    raise];
		}
	}

	for (i = 0; strs[i] != NULL; i++)
		free(strs[i]);

	ret[pos] = 0;
	return ret;
}
@end
