/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFString.h"

#import "OTAssertionFailedException.h"
#import "OTTestSkippedException.h"

void
OTAssertImpl(id testCase, SEL test, bool condition, OFString *check,
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
OTSkipImpl(id testCase, SEL test, OFString *file, size_t line, ...)
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
