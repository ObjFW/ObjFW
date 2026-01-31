/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>

#ifdef HAVE_WCHAR_H
# include <wchar.h>
#endif

#if defined(HAVE_NEWLOCALE) && \
    (defined(HAVE_ASPRINTF_L) || defined(HAVE_USELOCALE))
# include <locale.h>
#endif
#ifdef HAVE_XLOCALE_H
# include <xlocale.h>
#endif

#ifdef OF_HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#import "OFASPrintF.h"
#import "OFLocale.h"
#import "OFString.h"
#import "OFString+Private.h"

#import "OFInitializationFailedException.h"

#define maxSubformatLen 64

#ifndef HAVE_ASPRINTF
/*
 * (v)asprintf might be declared, but HAVE_ASPRINTF not defined because
 * configure determined it is broken. In this case, we must make sure there is
 * no name clash.
 */
# define asprintf asprintf_
# define vasprintf vasprintf_
#endif

struct Context {
	const char *format;
	size_t formatLen;
	char subformat[maxSubformatLen + 1];
	size_t subformatLen;
	va_list arguments;
	char *buffer;
	size_t bufferLen;
	size_t i, last;
	enum {
		stateString,
		stateFormatFlags,
		stateFormatFieldWidth,
		stateFormatLengthModifier,
		stateFormatConversionSpecifier
	} state;
	enum {
		lengthModifierNone,
		lengthModifierHH,
		lengthModifierH,
		lengthModifierL,
		lengthModifierLL,
		lengthModifierJ,
		lengthModifierZ,
		lengthModifierT,
		lengthModifierCapitalL
	} lengthModifier;
	bool useLocale;
};

#if defined(HAVE_NEWLOCALE) && \
    (defined(HAVE_ASPRINTF_L) || defined(HAVE_USELOCALE))
static locale_t cLocale;

OF_CONSTRUCTOR()
{
	if ((cLocale = newlocale(LC_ALL_MASK, "C", NULL)) == NULL)
		@throw [OFInitializationFailedException exception];
}
#endif

#ifndef HAVE_ASPRINTF
static int
vasprintf(char **string, const char *format, va_list arguments)
{
	int length;
	size_t bufferLength = 128;

	*string = NULL;

	for (;;) {
		free(*string);

		if ((*string = malloc(bufferLength)) == NULL)
			return -1;

		length = vsnprintf(*string, bufferLength - 1, format,
		    arguments);

		if (length >= 0 && (size_t)length < bufferLength - 1)
			break;

		if (bufferLength > INT_MAX / 2) {
			free(*string);
			return -1;
		}

		bufferLength <<= 1;
	}

	if (length > 0 && (size_t)length != bufferLength - 1) {
		char *resized = realloc(*string, length + 1);

		/* Ignore if making it smaller failed. */
		if (resized != NULL)
			*string = resized;
	}

	return length;
}

static int
asprintf(char **string, const char *format, ...)
{
	int ret;
	va_list arguments;

	va_start(arguments, format);
	ret = vasprintf(string, format, arguments);
	va_end(arguments);

	return ret;
}
#endif

static bool
appendString(struct Context *ctx, const char *append, size_t appendLen)
{
	char *newBuf;

	if (appendLen == 0)
		return true;

	if ((newBuf = realloc(ctx->buffer,
	    ctx->bufferLen + appendLen + 1)) == NULL)
		return false;

	memcpy(newBuf + ctx->bufferLen, append, appendLen);

	ctx->buffer = newBuf;
	ctx->bufferLen += appendLen;

	return true;
}

static bool
appendSubformat(struct Context *ctx, const char *subformat,
    size_t subformatLen)
{
	if (ctx->subformatLen + subformatLen > maxSubformatLen)
		return false;

	memcpy(ctx->subformat + ctx->subformatLen, subformat, subformatLen);
	ctx->subformatLen += subformatLen;
	ctx->subformat[ctx->subformatLen] = 0;

	return true;
}

static bool
stringState(struct Context *ctx)
{
	if (ctx->format[ctx->i] == '%') {
		if (ctx->i > 0)
			if (!appendString(ctx, ctx->format + ctx->last,
			    ctx->i - ctx->last))
				return false;

		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;

		ctx->last = ctx->i + 1;
		ctx->state = stateFormatFlags;
	}

	return true;
}

static bool
formatFlagsState(struct Context *ctx)
{
	switch (ctx->format[ctx->i]) {
	case '-':
	case '+':
	case ' ':
	case '#':
	case '0':
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;

		break;
	case ',':
		/* ObjFW extension: Use decimal point from locale */
		ctx->useLocale = true;
		break;
	default:
		ctx->state = stateFormatFieldWidth;
		ctx->i--;

		break;
	}

	return true;
}

static bool
formatFieldWidthState(struct Context *ctx)
{
	if ((ctx->format[ctx->i] >= '0' && ctx->format[ctx->i] <= '9') ||
	    ctx->format[ctx->i] == '*' || ctx->format[ctx->i] == '.') {
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;
	} else {
		ctx->state = stateFormatLengthModifier;
		ctx->i--;
	}

	return true;
}

static bool
formatLengthModifierState(struct Context *ctx)
{
	/* Only one allowed */
	switch (ctx->format[ctx->i]) {
	case 'h': /* and also hh */
		if (ctx->formatLen > ctx->i + 1 &&
		    ctx->format[ctx->i + 1] == 'h') {
			if (!appendSubformat(ctx, ctx->format + ctx->i, 2))
				return false;

			ctx->i++;
			ctx->lengthModifier = lengthModifierHH;
		} else {
			if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
				return false;

			ctx->lengthModifier = lengthModifierH;
		}

		break;
	case 'l': /* and also ll */
		if (ctx->formatLen > ctx->i + 1 &&
		    ctx->format[ctx->i + 1] == 'l') {
#ifndef OF_WINDOWS
			if (!appendSubformat(ctx, ctx->format + ctx->i, 2))
				return false;
#else
			if (!appendSubformat(ctx, "I64", 3))
				return false;
#endif

			ctx->i++;
			ctx->lengthModifier = lengthModifierLL;
		} else {
			if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
				return false;

			ctx->lengthModifier = lengthModifierL;
		}

		break;
	case 'j':
#if defined(OF_WINDOWS)
		if (!appendSubformat(ctx, "I64", 3))
			return false;
#elif defined(_NEWLIB_VERSION) || defined(OF_HPUX)
		if (!appendSubformat(ctx, "ll", 2))
			return false;
#else
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;
#endif

		ctx->lengthModifier = lengthModifierJ;

		break;
	case 'z':
#if defined(OF_WINDOWS)
		if (sizeof(size_t) == 8)
			if (!appendSubformat(ctx, "I64", 3))
				return false;
#elif defined(_NEWLIB_VERSION) || defined(OF_HPUX)
		if (!appendSubformat(ctx, "l", 1))
			return false;
#else
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;
#endif

		ctx->lengthModifier = lengthModifierZ;

		break;
	case 't':
#if defined(OF_WINDOWS)
		if (sizeof(ptrdiff_t) == 8)
			if (!appendSubformat(ctx, "I64", 3))
				return false;
#elif defined(_NEWLIB_VERSION) || defined(OF_HPUX)
		if (!appendSubformat(ctx, "l", 1))
			return false;
#else
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;
#endif

		ctx->lengthModifier = lengthModifierT;

		break;
	case 'L':
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;

		ctx->lengthModifier = lengthModifierCapitalL;

		break;
#ifdef OF_WINDOWS
	case 'I': /* Win32 strangeness (I64 instead of ll or j) */
		if (ctx->formatLen > ctx->i + 2 &&
		    ctx->format[ctx->i + 1] == '6' &&
		    ctx->format[ctx->i + 2] == '4') {
			if (!appendSubformat(ctx, ctx->format + ctx->i, 3))
				return false;

			ctx->i += 2;
			ctx->lengthModifier = lengthModifierLL;
		} else
			ctx->i--;

		break;
#endif
#ifdef OF_IOS
	case 'q': /* iOS uses this for PRI?64 */
		if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
			return false;

		ctx->lengthModifier = lengthModifierLL;

		break;
#endif
	default:
		ctx->i--;

		break;
	}

	ctx->state = stateFormatConversionSpecifier;
	return true;
}

static bool
formatConversionSpecifierState(struct Context *ctx)
{
	char *tmp = NULL;
	int tmpLen = 0;
#if !defined(HAVE_NEWLOCALE) || \
    (!defined(HAVE_ASPRINTF_L) && !defined(HAVE_USELOCALE))
	OFString *point;
#endif

	if (!appendSubformat(ctx, ctx->format + ctx->i, 1))
		return false;

	switch (ctx->format[ctx->i]) {
	case '@':
		if (ctx->lengthModifier != lengthModifierNone)
			return false;

		ctx->subformat[ctx->subformatLen - 1] = 's';

		@try {
			id object;

			if ((object = va_arg(ctx->arguments, id)) != nil) {
				void *pool = objc_autoreleasePoolPush();

				tmpLen = asprintf(&tmp, ctx->subformat,
				    [object description].UTF8String);

				objc_autoreleasePoolPop(pool);
			} else
				tmpLen = asprintf(&tmp, ctx->subformat,
				    "(nil)");
		} @catch (id e) {
			free(ctx->buffer);
			@throw e;
		}

		break;
	case 'C':
		if (ctx->lengthModifier != lengthModifierNone)
			return false;

		ctx->subformat[ctx->subformatLen - 1] = 's';

		{
			char buffer[5];
			size_t len = _OFUTF8StringEncode(
			    va_arg(ctx->arguments, OFUnichar), buffer);

			if (len == 0)
				return false;

			buffer[len] = 0;
			tmpLen = asprintf(&tmp, ctx->subformat, buffer);
		}

		break;
	case 'S':
		if (ctx->lengthModifier != lengthModifierNone)
			return false;

		ctx->subformat[ctx->subformatLen - 1] = 's';

		{
			const OFUnichar *arg =
			    va_arg(ctx->arguments, const OFUnichar *);
			size_t j, len = OFUTF32StringLength(arg);
			char *buffer;

			if (SIZE_MAX / 4 < len || (SIZE_MAX / 4) - len < 1)
				return false;

			if ((buffer = malloc((len * 4) + 1)) == NULL)
				return false;

			j = 0;
			for (size_t i = 0; i < len; i++) {
				size_t cLen = _OFUTF8StringEncode(arg[i],
				    buffer + j);

				if (cLen == 0) {
					free(buffer);
					return false;
				}

				j += cLen;
			}
			buffer[j] = 0;

			tmpLen = asprintf(&tmp, ctx->subformat, buffer);

			free(buffer);
		}

		break;
	case 'd':
	case 'i':
		switch (ctx->lengthModifier) {
		case lengthModifierNone:
		case lengthModifierHH:
		case lengthModifierH:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, int));
			break;
		case lengthModifierL:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, long));
			break;
		case lengthModifierLL:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, long long));
			break;
		case lengthModifierJ:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, intmax_t));
			break;
		case lengthModifierZ:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, ssize_t));
			break;
		case lengthModifierT:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, ptrdiff_t));
			break;
		default:
			return false;
		}

		break;
	case 'o':
	case 'u':
	case 'x':
	case 'X':
		switch (ctx->lengthModifier) {
		case lengthModifierNone:
		case lengthModifierHH:
		case lengthModifierH:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, unsigned int));
			break;
		case lengthModifierL:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, unsigned long));
			break;
		case lengthModifierLL:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, unsigned long long));
			break;
		case lengthModifierJ:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, uintmax_t));
			break;
		case lengthModifierZ:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, size_t));
			break;
		case lengthModifierT:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, ptrdiff_t));
			break;
		default:
			return false;
		}

		break;
	case 'f':
	case 'F':
	case 'e':
	case 'E':
	case 'g':
	case 'G':
	case 'a':
	case 'A':
		switch (ctx->lengthModifier) {
		case lengthModifierNone:
		case lengthModifierL:
#if defined(HAVE_NEWLOCALE) && defined(HAVE_ASPRINTF_L)
			if (!ctx->useLocale)
				tmpLen = asprintf_l(&tmp, cLocale,
				    ctx->subformat,
				    va_arg(ctx->arguments, double));
			else
#elif defined(HAVE_NEWLOCALE) && defined(HAVE_USELOCALE)
			if (!ctx->useLocale) {
				locale_t previousLocale = uselocale(cLocale);
				tmpLen = asprintf(&tmp, ctx->subformat,
				    va_arg(ctx->arguments, double));
				uselocale(previousLocale);
			} else
#endif
				tmpLen = asprintf(&tmp, ctx->subformat,
				    va_arg(ctx->arguments, double));
			break;
		case lengthModifierCapitalL:
#if defined(HAVE_NEWLOCALE) && defined(HAVE_ASPRINTF_L)
			if (!ctx->useLocale)
				tmpLen = asprintf_l(&tmp, cLocale,
				    ctx->subformat,
				    va_arg(ctx->arguments, long double));
			else
#elif defined(HAVE_NEWLOCALE) && defined(HAVE_USELOCALE)
			if (!ctx->useLocale) {
				locale_t previousLocale = uselocale(cLocale);
				tmpLen = asprintf(&tmp, ctx->subformat,
				    va_arg(ctx->arguments, long double));
				uselocale(previousLocale);
			} else
#endif
				tmpLen = asprintf(&tmp, ctx->subformat,
				    va_arg(ctx->arguments, long double));
			break;
		default:
			return false;
		}

#if !defined(HAVE_NEWLOCALE) || \
    (!defined(HAVE_ASPRINTF_L) && !defined(HAVE_USELOCALE))
		if (tmpLen == -1)
			return false;

		/*
		 * If there's no asprintf_l and no uselocale, we have no other
		 * choice than to use this ugly hack to replace the locale's
		 * decimal point back to ".".
		 */
		point = [OFLocale decimalSeparator];

		if (!ctx->useLocale && point != nil && ![point isEqual: @"."]) {
			void *pool = objc_autoreleasePoolPush();
			char *tmp2;

			@try {
				OFMutableString *tmpStr = [OFMutableString
				    stringWithUTF8String: tmp
						  length: tmpLen];
				[tmpStr replaceOccurrencesOfString: point
							withString: @"."];

				if (tmpStr.UTF8StringLength > INT_MAX)
					return false;

				tmpLen = (int)tmpStr.UTF8StringLength;
				tmp2 = malloc(tmpLen);
				memcpy(tmp2, tmpStr.UTF8String, tmpLen);
			} @finally {
				free(tmp);
				objc_autoreleasePoolPop(pool);
			}

			tmp = tmp2;
		}
#endif

		break;
	case 'c':
		switch (ctx->lengthModifier) {
		case lengthModifierNone:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, int));
			break;
		case lengthModifierL:
#ifdef HAVE_WCHAR_H
# if WINT_MAX >= INT_MAX
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, wint_t));
# else
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, int));
# endif
			break;
#endif
		default:
			return false;
		}

		break;
	case 's':
		switch (ctx->lengthModifier) {
		case lengthModifierNone:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, const char *));
			break;
#ifdef HAVE_WCHAR_T
		case lengthModifierL:
			tmpLen = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, const wchar_t *));
			break;
#endif
		default:
			return false;
		}

		break;
	case 'p':
		if (ctx->lengthModifier != lengthModifierNone)
			return false;

		tmpLen = asprintf(&tmp, ctx->subformat,
		    va_arg(ctx->arguments, void *));

		break;
	case 'n':
		switch (ctx->lengthModifier) {
		case lengthModifierNone:
			*va_arg(ctx->arguments, int *) = (int)ctx->bufferLen;
			break;
		case lengthModifierHH:
			*va_arg(ctx->arguments, signed char *) =
			    (signed char)ctx->bufferLen;
			break;
		case lengthModifierH:
			*va_arg(ctx->arguments, short *) =
			    (short)ctx->bufferLen;
			break;
		case lengthModifierL:
			*va_arg(ctx->arguments, long *) =
			    (long)ctx->bufferLen;
			break;
		case lengthModifierLL:
			*va_arg(ctx->arguments, long long *) =
			    (long long)ctx->bufferLen;
			break;
		case lengthModifierJ:
			*va_arg(ctx->arguments, intmax_t *) =
			    (intmax_t)ctx->bufferLen;
			break;
		case lengthModifierZ:
			*va_arg(ctx->arguments, size_t *) =
			    (size_t)ctx->bufferLen;
			break;
		case lengthModifierT:
			*va_arg(ctx->arguments, ptrdiff_t *) =
			    (ptrdiff_t)ctx->bufferLen;
			break;
		default:
			return false;
		}

		break;
	case '%':
		if (ctx->lengthModifier != lengthModifierNone)
			return false;

		if (!appendString(ctx, "%", 1))
			return false;

		break;
	default:
		return false;
	}

	if (tmpLen == -1)
		return false;

	if (tmp != NULL) {
		if (!appendString(ctx, tmp, tmpLen)) {
			free(tmp);
			return false;
		}

		free(tmp);
	}

	memset(ctx->subformat, 0, maxSubformatLen);
	ctx->subformatLen = 0;
	ctx->lengthModifier = lengthModifierNone;
	ctx->useLocale = false;

	ctx->last = ctx->i + 1;
	ctx->state = stateString;

	return true;
}

static bool (*states[])(struct Context *) = {
	stringState,
	formatFlagsState,
	formatFieldWidthState,
	formatLengthModifierState,
	formatConversionSpecifierState
};

int
_OFVASPrintF(char **string, const char *format, va_list arguments)
{
	struct Context ctx;

	ctx.format = format;
	ctx.formatLen = strlen(format);
	memset(ctx.subformat, 0, maxSubformatLen + 1);
	ctx.subformatLen = 0;
	va_copy(ctx.arguments, arguments);
	ctx.bufferLen = 0;
	ctx.last = 0;
	ctx.state = stateString;
	ctx.lengthModifier = lengthModifierNone;
	ctx.useLocale = false;

	if ((ctx.buffer = malloc(1)) == NULL)
		return -1;

	for (ctx.i = 0; ctx.i < ctx.formatLen; ctx.i++) {
		if (!states[ctx.state](&ctx)) {
			free(ctx.buffer);
			return -1;
		}
	}

	if (ctx.state != stateString) {
		free(ctx.buffer);
		return -1;
	}

	if (!appendString(&ctx, ctx.format + ctx.last,
	    ctx.formatLen - ctx.last)) {
		free(ctx.buffer);
		return -1;
	}

	ctx.buffer[ctx.bufferLen] = 0;

	*string = ctx.buffer;
	return (ctx.bufferLen <= INT_MAX ? (int)ctx.bufferLen : -1);
}
