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

#define _GNU_SOURCE
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <limits.h>
#include <wchar.h>

#import "OFString.h"
#import "OFAutoreleasePool.h"
#import "asprintf.h"

#define MAX_SUBFMT_LEN 64

struct context {
	const char *fmt;
	size_t fmt_len;
	char subfmt[MAX_SUBFMT_LEN + 1];
	size_t subfmt_len;
	va_list args;
	char *buf;
	size_t buf_len;
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
	} len_mod;
};

static bool
append_str(struct context *ctx, const char *astr, size_t astr_len)
{
	char *nbuf;

	if (astr_len == 0)
		return true;

	if ((nbuf = realloc(ctx->buf, ctx->buf_len + astr_len + 1)) == NULL)
		return false;

	memcpy(nbuf + ctx->buf_len, astr, astr_len);

	ctx->buf = nbuf;
	ctx->buf_len += astr_len;

	return true;
}

static bool
append_subfmt(struct context *ctx, const char *asubfmt, size_t asubfmt_len)
{
	if (ctx->subfmt_len + asubfmt_len > MAX_SUBFMT_LEN)
		return false;

	memcpy(ctx->subfmt + ctx->subfmt_len, asubfmt, asubfmt_len);
	ctx->subfmt_len += asubfmt_len;
	ctx->subfmt[ctx->subfmt_len] = 0;

	return true;
}

static bool
state_string(struct context *ctx)
{
	if (ctx->fmt[ctx->i] == '%') {
		if (ctx->i > 0)
			if (!append_str(ctx, ctx->fmt + ctx->last,
			    ctx->i - ctx->last))
				return false;

		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
			return false;

		ctx->last = ctx->i + 1;
		ctx->state = STATE_FORMAT_FLAGS;
	}

	return true;
}

static bool
state_format_flags(struct context *ctx)
{
	switch (ctx->fmt[ctx->i]) {
	case '-':
	case '+':
	case ' ':
	case '#':
	case '0':
		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
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
	if ((ctx->fmt[ctx->i] >= '0' && ctx->fmt[ctx->i] <= '9') ||
	    ctx->fmt[ctx->i] == '*' || ctx->fmt[ctx->i] == '.') {
		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
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
	switch (ctx->fmt[ctx->i]) {
	case 'h': /* and also hh */
		if (ctx->fmt_len > ctx->i + 1 && ctx->fmt[ctx->i + 1] == 'h') {
			if (!append_subfmt(ctx, ctx->fmt + ctx->i, 2))
				return false;

			ctx->i++;
			ctx->len_mod = LENGTH_MODIFIER_HH;
		} else {
			if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
				return false;

			ctx->len_mod = LENGTH_MODIFIER_H;
		}

		break;
	case 'l': /* and also ll */
		if (ctx->fmt_len > ctx->i + 1 && ctx->fmt[ctx->i + 1] == 'l') {
			if (!append_subfmt(ctx, ctx->fmt + ctx->i, 2))
				return false;

			ctx->i++;
			ctx->len_mod = LENGTH_MODIFIER_LL;
		} else {
			if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
				return false;

			ctx->len_mod = LENGTH_MODIFIER_L;
		}

		break;
	case 'j':
		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
			return false;

		ctx->len_mod = LENGTH_MODIFIER_J;

		break;
	case 'z':
		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
			return false;

		ctx->len_mod = LENGTH_MODIFIER_Z;

		break;
	case 't':
		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
			return false;

		ctx->len_mod = LENGTH_MODIFIER_T;

		break;
	case 'L':
		if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
			return false;

		ctx->len_mod = LENGTH_MODIFIER_CAPITAL_L;

		break;
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

	if (!append_subfmt(ctx, ctx->fmt + ctx->i, 1))
		return false;

	switch (ctx->fmt[ctx->i]) {
	case '@':;
		OFAutoreleasePool *pool;

		ctx->subfmt[ctx->subfmt_len - 1] = 's';

		@try {
			pool = [[OFAutoreleasePool alloc] init];
		} @catch (id e) {
			[e release];
			return false;
		}

		@try {
			id obj;

			if ((obj = va_arg(ctx->args, id)) != nil)
				tmp_len = asprintf(&tmp, ctx->subfmt,
				    [[obj description] cString]);
			else
				if (!append_str(ctx, "(nil)", 5))
					return false;
		} @catch (id e) {
			[e release];
			return false;
		} @finally {
			[pool release];
		}

		break;
	case 'd':
	case 'i':
		switch (ctx->len_mod) {
		case LENGTH_MODIFIER_NONE:
		case LENGTH_MODIFIER_HH:
		case LENGTH_MODIFIER_H:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, int));
			break;
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, long));
			break;
		case LENGTH_MODIFIER_LL:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, long long));
			break;
		case LENGTH_MODIFIER_J:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, intmax_t));
			break;
		case LENGTH_MODIFIER_Z:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, ssize_t));
			break;
		case LENGTH_MODIFIER_T:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, ptrdiff_t));
			break;
		default:
			return false;
		}

		break;
	case 'o':
	case 'u':
	case 'x':
	case 'X':
		switch (ctx->len_mod) {
		case LENGTH_MODIFIER_NONE:
		case LENGTH_MODIFIER_HH:
		case LENGTH_MODIFIER_H:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, unsigned int));
			break;
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, unsigned long));
			break;
		case LENGTH_MODIFIER_LL:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, unsigned long long));
			break;
		case LENGTH_MODIFIER_J:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, uintmax_t));
			break;
		case LENGTH_MODIFIER_Z:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, size_t));
			break;
		case LENGTH_MODIFIER_T:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, ptrdiff_t));
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
		switch (ctx->len_mod) {
		case LENGTH_MODIFIER_NONE:
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, double));
			break;
		case LENGTH_MODIFIER_CAPITAL_L:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, long double));
			break;
		default:
			return false;
		}

		break;
	case 'c':
		switch (ctx->len_mod) {
		case LENGTH_MODIFIER_NONE:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, int));
			break;
		case LENGTH_MODIFIER_L:
#if WINT_MAX >= INT_MAX
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, wint_t));
#else
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, int));
#endif
			break;
		default:
			return false;
		}

		break;
	case 's':
		switch (ctx->len_mod) {
		case LENGTH_MODIFIER_NONE:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, const char*));
			break;
		case LENGTH_MODIFIER_L:
			tmp_len = asprintf(&tmp, ctx->subfmt,
			    va_arg(ctx->args, const wchar_t*));
			break;
		default:
			return false;
		}

		break;
	case 'p':
		if (ctx->len_mod != LENGTH_MODIFIER_NONE)
			return false;

		tmp_len = asprintf(&tmp, ctx->subfmt, va_arg(ctx->args, void*));

		break;
	case 'n':
		switch (ctx->len_mod) {
		case LENGTH_MODIFIER_NONE:
			*va_arg(ctx->args, int*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_HH:
			*va_arg(ctx->args, signed char*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_H:
			*va_arg(ctx->args, short*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_L:
			*va_arg(ctx->args, long*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_LL:
			*va_arg(ctx->args, long long*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_J:
			*va_arg(ctx->args, intmax_t*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_Z:
			*va_arg(ctx->args, size_t*) = ctx->buf_len;
			break;
		case LENGTH_MODIFIER_T:
			*va_arg(ctx->args, ptrdiff_t*) = ctx->buf_len;
			break;
		default:
			return false;
		}

		break;
	case '%':
		if (ctx->len_mod != LENGTH_MODIFIER_NONE)
			return false;

		if (!append_str(ctx, "%", 1))
			return false;

		break;
	default:
		return false;
	}

	if (tmp_len == -1)
		return false;

	if (tmp != NULL) {
		if (!append_str(ctx, tmp, tmp_len)) {
			free(tmp);
			return false;
		}

		free(tmp);
	}

	memset(ctx->subfmt, 0, MAX_SUBFMT_LEN);
	ctx->subfmt_len = 0;
	ctx->len_mod = LENGTH_MODIFIER_NONE;

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
of_vasprintf(char **ret, const char *fmt, va_list args)
{
	struct context ctx;

	ctx.fmt = fmt;
	ctx.fmt_len = strlen(fmt);
	memset(ctx.subfmt, 0, MAX_SUBFMT_LEN + 1);
	ctx.subfmt_len = 0;
	va_copy(ctx.args, args);
	ctx.buf_len = 0;
	ctx.last = 0;
	ctx.state = STATE_STRING;
	ctx.len_mod = LENGTH_MODIFIER_NONE;

	if ((ctx.buf = malloc(1)) == NULL)
		return -1;

	for (ctx.i = 0; ctx.i < ctx.fmt_len; ctx.i++) {
		if (!states[ctx.state](&ctx)) {
			if (ctx.buf != NULL)
				free(ctx.buf);

			return -1;
		}
	}

	if (ctx.state != STATE_STRING) {
		if (ctx.buf != NULL)
			free(ctx.buf);

		return -1;
	}

	if (!append_str(&ctx, ctx.fmt + ctx.last, ctx.fmt_len - ctx.last)) {
		free(ctx.buf);
		return -1;
	}

	ctx.buf[ctx.buf_len] = 0;

	*ret = ctx.buf;
	return ctx.buf_len;
}

int
of_asprintf(char **ret, const char *fmt, ...)
{
	va_list args;
	int r;

	va_start(args, fmt);
	r = of_vasprintf(ret, fmt, args);
	va_end(args);

	return r;
}
