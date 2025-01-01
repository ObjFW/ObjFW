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

#import "OFString.h"

#import "OTAssertionFailedException.h"
#import "OTTestSkippedException.h"

void
_OTAssertImpl(id testCase, SEL test, bool condition, OFString *check,
    OFString *file, size_t line, ...)
{
	va_list arguments;
	OFConstantString *format;
	OFString *message = nil;

	if (condition)
		return;

	va_start(arguments, line);
	format = va_arg(arguments, OFConstantString *);

	if (format != nil)
		message = [[[OFString alloc]
		    initWithFormat: format
			 arguments: arguments] autorelease];

	va_end(arguments);

	@throw [OTAssertionFailedException exceptionWithCondition: check
							  message: message];
}

void
_OTSkipImpl(id testCase, SEL test, OFString *file, size_t line, ...)
{
	va_list arguments;
	OFConstantString *format;
	OFString *message = nil;

	va_start(arguments, line);
	format = va_arg(arguments, OFConstantString *);

	if (format != nil)
		message = [[[OFString alloc]
		    initWithFormat: format
			 arguments: arguments] autorelease];

	va_end(arguments);

	@throw [OTTestSkippedException exceptionWithMessage: message];
}
