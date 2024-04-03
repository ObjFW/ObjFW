/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#include <time.h>

#import "OFStrFTime.h"
#import "macros.h"

static const char weekDays[7][4] = {
	"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};
static const char monthNames[12][4] = {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct",
	"Nov", "Dec"
};

size_t
OFStrFTime(char *buffer, size_t bufferLen, const char *format, struct tm *tm,
    short tz)
{
	enum {
		stateSearchConversionSpecifier,
		stateInConversionSpecifier
	} state = stateSearchConversionSpecifier;
	size_t j, formatLen;

	if (bufferLen == 0)
		return 0;

	formatLen = strlen(format);

	j = 0;
	for (size_t i = 0; i < formatLen; i++) {
		switch (state) {
		case stateSearchConversionSpecifier:
			if (format[i] == '%')
				state = stateInConversionSpecifier;
			else {
				if (j >= bufferLen)
					return 0;

				buffer[j++] = format[i];
			}

			break;
		case stateInConversionSpecifier:;
			const char *appendFormat;
			unsigned int value = 0;
			char append[5];
			int appendLen;

			switch (format[i]) {
			case '%':
				appendFormat = "%%";
				break;
			case 'a':
				if (tm->tm_wday > 6)
					return 0;

				appendFormat = weekDays[tm->tm_wday];
				break;
			case 'b':
				if (tm->tm_mon > 11)
					return 0;

				appendFormat = monthNames[tm->tm_mon];
				break;
			case 'd':
				appendFormat = "%02u";
				value = tm->tm_mday;
				break;
			case 'e':
				appendFormat = "%2u";
				value = tm->tm_mday;
				break;
			case 'H':
				appendFormat = "%02u";
				value = tm->tm_hour;
				break;
			case 'M':
				appendFormat = "%02u";
				value = tm->tm_min;
				break;
			case 'm':
				appendFormat = "%02u";
				value = tm->tm_mon + 1;
				break;
			case 'n':
				appendFormat = "\n";
				break;
			case 'S':
				appendFormat = "%02u";
				value = tm->tm_sec;
				break;
			case 't':
				appendFormat = "\t";
				break;
			case 'Y':
				appendFormat = "%4u";
				value = tm->tm_year + 1900;
				break;
			case 'y':
				appendFormat = "%02u";
				value = tm->tm_year;

				while (value > 100)
					value -= 100;

				break;
			case 'z':
				if (tz == 0)
					appendFormat = "Z";
				else if (tz >= 0) {
					appendFormat = "+%04u";
					value = tz;
				} else {
					appendFormat = "-%04u";
					value = -tz;
				}

				value = (value / 60) * 100 + (value % 60);
				break;
			default:
				return 0;
			}

			appendLen = snprintf(append, sizeof(append),
			    appendFormat, value);
			if (appendLen < 0 ||
			    (size_t)appendLen >= sizeof(append))
				return 0;

			if (bufferLen - j < (size_t)appendLen)
				return 0;

			memcpy(buffer + j, append, appendLen);
			j += appendLen;

			state = stateSearchConversionSpecifier;
		}
	}

	if (j >= bufferLen)
		return 0;

	buffer[j] = 0;

	return j;
}
