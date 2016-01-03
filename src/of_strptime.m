/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include <string.h>

#include <time.h>

const char*
of_strptime(const char *buffer, const char *format, struct tm *tm)
{
	enum {
		SEARCH_CONVERSION_SPECIFIER,
		IN_CONVERSION_SPECIFIER
	} state = SEARCH_CONVERSION_SPECIFIER;
	size_t i, j, buffer_len, format_len;

	buffer_len = strlen(buffer);
	format_len = strlen(format);

	for (i = j = 0; i < format_len; i++) {
		if (j >= buffer_len)
			return NULL;

		switch (state) {
		case SEARCH_CONVERSION_SPECIFIER:
			if (format[i] == '%')
				state = IN_CONVERSION_SPECIFIER;
			else if (format[i] != buffer[j++])
				return NULL;

			break;

		case IN_CONVERSION_SPECIFIER:;
			int k, max_len, number = 0;

			switch (format[i]) {
			case 'd':
			case 'e':
			case 'H':
			case 'm':
			case 'M':
			case 'S':
			case 'y':
				max_len = 2;
				break;
			case 'Y':
				max_len = 4;
				break;
			case '%':
			case 'n':
			case 't':
				max_len = 0;
				break;
			default:
				return NULL;
			}

			if (max_len > 0 && (buffer[j] < '0' || buffer[j] > '9'))
				return NULL;

			for (k = 0; k < max_len && j < buffer_len &&
			    buffer[j] >= '0' && buffer[j] <= '9'; k++, j++) {
				number *= 10;
				number += buffer[j] - '0';
			}

			switch (format[i]) {
			case 'd':
			case 'e':
				tm->tm_mday = number;
				break;
			case 'H':
				tm->tm_hour = number;
				break;
			case 'm':
				tm->tm_mon = number - 1;
				break;
			case 'M':
				tm->tm_min = number;
				break;
			case 'S':
				tm->tm_sec = number;
				break;
			case 'y':
				if (number <= 68)
					number += 100;

				tm->tm_year = number;
				break;
			case 'Y':
				if (number < 1900)
					return NULL;

				tm->tm_year = number - 1900;
				break;
			case '%':
				if (buffer[j++] != '%')
					return NULL;
				break;
			case 'n':
			case 't':
				if (buffer[j] != ' ' && buffer[j] != '\r' &&
				    buffer[j] != '\n' && buffer[j] != '\t' &&
				    buffer[j] != '\f')
					return NULL;

				j++;
				break;
			}

			state = SEARCH_CONVERSION_SPECIFIER;

			break;
		}
	}

	return buffer + j;
}
