/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFStrPTime.h"
#import "macros.h"

const char *
_OFStrPTime(const char *buffer, const char *format, struct tm *tm, short *tz)
{
	enum {
		stateSearchConversionSpecifier,
		stateInConversionSpecifier
	} state = stateSearchConversionSpecifier;
	size_t j, bufferLen, formatLen;

	bufferLen = strlen(buffer);
	formatLen = strlen(format);

	j = 0;
	for (size_t i = 0; i < formatLen; i++) {
		if (j >= bufferLen)
			return NULL;

		switch (state) {
		case stateSearchConversionSpecifier:
			if (format[i] == '%')
				state = stateInConversionSpecifier;
			else if (format[i] != buffer[j++])
				return NULL;

			break;
		case stateInConversionSpecifier:;
			int k, maxLen, number = 0;

			switch (format[i]) {
			case 'd':
			case 'e':
			case 'H':
			case 'm':
			case 'M':
			case 'S':
			case 'y':
				maxLen = 2;
				break;
			case 'Y':
				maxLen = 4;
				break;
			case '%':
			case 'a':
			case 'b':
			case 'n':
			case 't':
			case 'z':
				maxLen = 0;
				break;
			default:
				return NULL;
			}

			if (maxLen > 0 && (buffer[j] < '0' || buffer[j] > '9'))
				return NULL;

			for (k = 0; k < maxLen && j < bufferLen &&
			    buffer[j] >= '0' && buffer[j] <= '9'; k++, j++) {
				number *= 10;
				number += buffer[j] - '0';
			}

			switch (format[i]) {
			case 'a':
				if (bufferLen < j + 3)
					return NULL;

				if (memcmp(buffer + j, "Sun", 3) == 0)
					tm->tm_wday = 0;
				else if (memcmp(buffer + j, "Mon", 3) == 0)
					tm->tm_wday = 1;
				else if (memcmp(buffer + j, "Tue", 3) == 0)
					tm->tm_wday = 2;
				else if (memcmp(buffer + j, "Wed", 3) == 0)
					tm->tm_wday = 3;
				else if (memcmp(buffer + j, "Thu", 3) == 0)
					tm->tm_wday = 4;
				else if (memcmp(buffer + j, "Fri", 3) == 0)
					tm->tm_wday = 5;
				else if (memcmp(buffer + j, "Sat", 3) == 0)
					tm->tm_wday = 6;
				else
					return NULL;

				j += 3;
				break;
			case 'b':
				if (bufferLen < j + 3)
					return NULL;

				if (memcmp(buffer + j, "Jan", 3) == 0)
					tm->tm_mon = 0;
				else if (memcmp(buffer + j, "Feb", 3) == 0)
					tm->tm_mon = 1;
				else if (memcmp(buffer + j, "Mar", 3) == 0)
					tm->tm_mon = 2;
				else if (memcmp(buffer + j, "Apr", 3) == 0)
					tm->tm_mon = 3;
				else if (memcmp(buffer + j, "May", 3) == 0)
					tm->tm_mon = 4;
				else if (memcmp(buffer + j, "Jun", 3) == 0)
					tm->tm_mon = 5;
				else if (memcmp(buffer + j, "Jul", 3) == 0)
					tm->tm_mon = 6;
				else if (memcmp(buffer + j, "Aug", 3) == 0)
					tm->tm_mon = 7;
				else if (memcmp(buffer + j, "Sep", 3) == 0)
					tm->tm_mon = 8;
				else if (memcmp(buffer + j, "Oct", 3) == 0)
					tm->tm_mon = 9;
				else if (memcmp(buffer + j, "Nov", 3) == 0)
					tm->tm_mon = 10;
				else if (memcmp(buffer + j, "Dec", 3) == 0)
					tm->tm_mon = 11;
				else
					return NULL;

				j += 3;
				break;
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
			case 'z':
				if (buffer[j] == '-' || buffer[j] == '+') {
					const char *b = buffer + j;

					if (bufferLen < j + 5)
						return NULL;

					if (tz == NULL)
						break;

					*tz = (((short)b[1] - '0') * 600 +
					    ((short)b[2] - '0') * 60 +
					    ((short)b[3] - '0') * 10 +
					    ((short)b[4] - '0')) *
					    (b[0] == '-' ? -1 : 1);

					j += 5;
				} else if (buffer[j] == 'Z') {
					if (tz != NULL)
						*tz = 0;

					j++;
				} else if (buffer[j] == 'G') {
					if (bufferLen < j + 3)
						return NULL;

					if (buffer[j + 1] != 'M' ||
					    buffer[j + 2] != 'T')
						return NULL;

					if (tz != NULL)
						*tz = 0;

					j += 3;
				} else
					return NULL;

				break;
			case '%':
				if (buffer[j++] != '%')
					return NULL;
				break;
			case 'n':
				if (buffer[j++] != '\n')
					return NULL;
				break;
			case 't':
				if (buffer[j++] != '\t')
					return NULL;
				break;
			}

			state = stateSearchConversionSpecifier;

			break;
		}
	}

	return buffer + j;
}
