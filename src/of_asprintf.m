/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <wchar.h>

#include <sys/types.h>

#import "OFString.h"

#import "asprintf.h"
#import "autorelease.h"
#import "macros.h"

#define MAX_SUBFORMAT_LEN 64

struct context {
	const char *format;
	size_t format_len;
	char subformat[MAX_SUBFORMAT_LEN + 1];
	size_t subformat_len;
	va_list arguments;
	char *buffer;
	size_t buffer_len;
	size_t i, last;
	enum {
		STATE_STRING,
		STATE_FORMAT_FLAGS,
		STATE_FORMAT_FIELD_WIDTH,
		STATE_FORMAT_LENGTH_MODIFIER,
		STATE_FORMAT_CONVERSION_SPECIFIER
	} state;
	enum {
		LENGTH_MODIFIER_NONE,
		LENGTH_MODIFIER_HH,
		LENGTH_MODIFIER_H,
		LENGTH_MODIFIER_L,
		LENGTH_MODIFIER_LL,
		LENGTH_MODIFIER_J,
		LENGTH_MODIFIER_Z,
		LENGTH_MODIFIER_T,
		LENGTH_MODIFIER_CAPITAL_L
	} length_modifier;
};

static bool
append_string(struct context *ctx, const char *append, size_t append_len)
{
	char *new_buf;

	if (append_len == 0)
		return true;

	if ((new_buf = realloc(ctx->buffer,
	    ctx->buffer_len + append_len + 1)) == NULL)
		return false;

	memcpy(new_buf + ctx->buffer_len, append, append_len);

	ctx->buffer = new_buf;
	ctx->buffer_len += append_len;

	return true;
}

static bool
append_subformat(struct context *ctx, const char *subformat,
    size_t subformat_len)
{
	if (ctx->subformat_len + subformat_len > MAX_SUBFORMAT_LEN)
		return false;

	memcpy(ctx->subformat + ctx->subformat_len, subformat, subformat_len);
	ctx->subformat_len += subformat_len;
	ctx->subformat[ctx->subformat_len] = 0;

	return true;
}

static bool
state_string(struct context *ctx)
{
	if (ctx->format[ctx->i] == '%') {
		if (ctx->i > 0)
			if (!append_string(ctx, ctx->format + ctx->last,
			    ctx->i - ctx->last))
				return false;

		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;

		ctx->last = ctx->i + 1;
		ctx->state = STATE_FORMAT_FLAGS;
	}

	return true;
}

static bool
state_format_flags(struct context *ctx)
{
	switch (ctx->format[ctx->i]) {
	case '-':
	case '+':
	case ' ':
	case '#':
	case '0':
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;

		break;
	default:
		ctx->state = STATE_FORMAT_FIELD_WIDTH;
		ctx->i--;

		break;
	}

	return true;
}

static bool
state_format_field_width(struct context *ctx)
{
	if ((ctx->format[ctx->i] >= '0' && ctx->format[ctx->i] <= '9') ||
	    ctx->format[ctx->i] == '*' || ctx->format[ctx->i] == '.') {
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;
	} else {
		ctx->state = STATE_FORMAT_LENGTH_MODIFIER;
		ctx->i--;
	}

	return true;
}

static bool
state_format_length_modifier(struct context *ctx)
{
	/* Only one allowed */
	switch (ctx->format[ctx->i]) {
	case 'h': /* and also hh */
		if (ctx->format_len > ctx->i + 1 &&
		    ctx->format[ctx->i + 1] == 'h') {
			if (!append_subformat(ctx, ctx->format + ctx->i, 2))
				return false;

			ctx->i++;
			ctx->length_modifier = LENGTH_MODIFIER_HH;
		} else {
			if (!append_subformat(ctx, ctx->format + ctx->i, 1))
				return false;

			ctx->length_modifier = LENGTH_MODIFIER_H;
		}

		break;
	case 'l': /* and also ll */
		if (ctx->format_len > ctx->i + 1 &&
		    ctx->format[ctx->i + 1] == 'l') {
#ifndef _WIN32
			if (!append_subformat(ctx, ctx->format + ctx->i, 2))
				return false;
#else
			if (!append_subformat(ctx, "I64", 3))
				return false;
#endif

			ctx->i++;
			ctx->length_modifier = LENGTH_MODIFIER_LL;
		} else {
			if (!append_subformat(ctx, ctx->format + ctx->i, 1))
				return false;

			ctx->length_modifier = LENGTH_MODIFIER_L;
		}

		break;
	case 'j':
#ifndef _WIN32
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;
#else
		if (!append_subformat(ctx, "I64", 3))
			return false;
#endif

		ctx->length_modifier = LENGTH_MODIFIER_J;

		break;
	case 'z':
#ifndef _WIN32
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;
#else
		if (!append_subformat(ctx, "I", 1))
			return false;
#endif

		ctx->length_modifier = LENGTH_MODIFIER_Z;

		break;
	case 't':
#ifndef _WIN32
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;
#else
		if (!append_subformat(ctx, "I", 1))
			return false;
#endif

		ctx->length_modifier = LENGTH_MODIFIER_T;

		break;
	case 'L':
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;

		ctx->length_modifier = LENGTH_MODIFIER_CAPITAL_L;

		break;
#ifdef _WIN32
	case 'I': /* win32 strangeness (I64 instead of ll or j) */
		if (ctx->formatLen > ctx->i + 2 &&
		    ctx->format[ctx->i + 1] == '6' &&
		    ctx->format[ctx->i + 2] == '4') {
			if (!append_subformat(ctx, ctx->format + ctx->i, 3))
				return false;

			ctx->i += 2;
			ctx->lengthModifier = LENGTH_MODIFIER_LL;
		} else
			ctx->i--;

		break;
#endif
#ifdef OF_IOS
	case 'q': /* iOS uses this for PRI?64 */
		if (!append_subformat(ctx, ctx->format + ctx->i, 1))
			return false;

		ctx->lengthModifier = LENGTH_MODIFIER_LL;

		break;
#endif
	default:
		ctx->i--;

		break;
	}

	ctx->state = STATE_FORMAT_CONVERSION_SPECIFIER;
	return true;
}

static bool
state_format_conversion_specifier(struct context *ctx)
{
	char *tmp = NULL;
	int tmp_len = 0;

	if (!append_subformat(ctx, ctx->format + ctx->i, 1))
		return false;

	switch (ctx->format[ctx->i]) {
	case '@':
		ctx->subformat[ctx->subformat_len - 1] = 's';

		@try {
			id object;

			if ((object = va_arg(ctx->arguments, id)) != nil) {
				void *pool = objc_autoreleasePoolPush();

				tmp_len = asprintf(&tmp, ctx->subformat,
				    [[object description] UTF8String]);

				objc_autoreleasePoolPop(pool);
			} else
				tmp_len = asprintf(&tmp, ctx->subformat,
				    "(nil)");
		} @catch (id e) {
			free(ctx->buffer);
			@throw e;
		}

		break;
	case 'd':
	case 'i':
		switch (ctx->length_modifier) {
		case LENGTH_MODIFIER_NONE:
		case LENGTH_MODIFIER_HH:
		case LENGTH_MODIFIER_H:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, int));
			break;
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, long));
			break;
		case LENGTH_MODIFIER_LL:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, long long));
			break;
		case LENGTH_MODIFIER_J:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, intmax_t));
			break;
		case LENGTH_MODIFIER_Z:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, ssize_t));
			break;
		case LENGTH_MODIFIER_T:
			tmp_len = asprintf(&tmp, ctx->subformat,
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
		switch (ctx->length_modifier) {
		case LENGTH_MODIFIER_NONE:
		case LENGTH_MODIFIER_HH:
		case LENGTH_MODIFIER_H:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, unsigned int));
			break;
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, unsigned long));
			break;
		case LENGTH_MODIFIER_LL:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, unsigned long long));
			break;
		case LENGTH_MODIFIER_J:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, uintmax_t));
			break;
		case LENGTH_MODIFIER_Z:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, size_t));
			break;
		case LENGTH_MODIFIER_T:
			tmp_len = asprintf(&tmp, ctx->subformat,
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
		switch (ctx->length_modifier) {
		case LENGTH_MODIFIER_NONE:
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, double));
			break;
		case LENGTH_MODIFIER_CAPITAL_L:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, long double));
			break;
		default:
			return false;
		}

		break;
	case 'c':
		switch (ctx->length_modifier) {
		case LENGTH_MODIFIER_NONE:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, int));
			break;
		case LENGTH_MODIFIER_L:
#if WINT_MAX >= INT_MAX
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, wint_t));
#else
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, int));
#endif
			break;
		default:
			return false;
		}

		break;
	case 's':
		switch (ctx->length_modifier) {
		case LENGTH_MODIFIER_NONE:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, const char*));
			break;
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subformat,
			    va_arg(ctx->arguments, const wchar_t*));
			break;
		default:
			return false;
		}

		break;
	case 'p':
		if (ctx->length_modifier != LENGTH_MODIFIER_NONE)
			return false;

		tmp_len = asprintf(&tmp, ctx->subformat,
		    va_arg(ctx->arguments, void*));

		break;
	case 'n':
		switch (ctx->length_modifier) {
		case LENGTH_MODIFIER_NONE:
			*va_arg(ctx->arguments, int*) =
			    (int)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_HH:
			*va_arg(ctx->arguments, signed char*) =
			    (signed char)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_H:
			*va_arg(ctx->arguments, short*) =
			    (short)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_L:
			*va_arg(ctx->arguments, long*) =
			    (long)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_LL:
			*va_arg(ctx->arguments, long long*) =
			    (long long)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_J:
			*va_arg(ctx->arguments, intmax_t*) =
			    (intmax_t)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_Z:
			*va_arg(ctx->arguments, size_t*) =
			    (size_t)ctx->buffer_len;
			break;
		case LENGTH_MODIFIER_T:
			*va_arg(ctx->arguments, ptrdiff_t*) =
			    (ptrdiff_t)ctx->buffer_len;
			break;
		default:
			return false;
		}

		break;
	case '%':
		if (ctx->length_modifier != LENGTH_MODIFIER_NONE)
			return false;

		if (!append_string(ctx, "%", 1))
			return false;

		break;
	default:
		return false;
	}

	if (tmp_len == -1)
		return false;

	if (tmp != NULL) {
		if (!append_string(ctx, tmp, tmp_len)) {
			free(tmp);
			return false;
		}

		free(tmp);
	}

	memset(ctx->subformat, 0, MAX_SUBFORMAT_LEN);
	ctx->subformat_len = 0;
	ctx->length_modifier = LENGTH_MODIFIER_NONE;

	ctx->last = ctx->i + 1;
	ctx->state = STATE_STRING;

	return true;
}

static bool (*states[])(struct context*) = {
	state_string,
	state_format_flags,
	state_format_field_width,
	state_format_length_modifier,
	state_format_conversion_specifier
};

int
of_vasprintf(char **string, const char *format, va_list arguments)
{
	struct context ctx;

	ctx.format = format;
	ctx.format_len = strlen(format);
	memset(ctx.subformat, 0, MAX_SUBFORMAT_LEN + 1);
	ctx.subformat_len = 0;
	va_copy(ctx.arguments, arguments);
	ctx.buffer_len = 0;
	ctx.last = 0;
	ctx.state = STATE_STRING;
	ctx.length_modifier = LENGTH_MODIFIER_NONE;

	if ((ctx.buffer = malloc(1)) == NULL)
		return -1;

	for (ctx.i = 0; ctx.i < ctx.format_len; ctx.i++) {
		if (!states[ctx.state](&ctx)) {
			free(ctx.buffer);
			return -1;
		}
	}

	if (ctx.state != STATE_STRING) {
		free(ctx.buffer);
		return -1;
	}

	if (!append_string(&ctx, ctx.format + ctx.last,
	    ctx.format_len - ctx.last)) {
		free(ctx.buffer);
		return -1;
	}

	ctx.buffer[ctx.buffer_len] = 0;

	*string = ctx.buffer;
	return (ctx.buffer_len <= INT_MAX ? (int)ctx.buffer_len : -1);
}

int
of_asprintf(char **string, const char *format, ...)
{
	va_list arguments;
	int ret;

	va_start(arguments, format);
	ret = of_vasprintf(string, format, arguments);
	va_end(arguments);

	return ret;
}
