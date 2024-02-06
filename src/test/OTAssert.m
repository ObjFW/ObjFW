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

#import "OFColor.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "OTAssertionFailedException.h"

void
OTAssertImpl(id testCase, SEL test, bool condition, OFString *check,
    OFString *file, size_t line, ...)
{
	void *pool;
	va_list arguments;
	OFConstantString *format;
	OFString *message = nil;

	if (condition)
		return;

	pool = objc_autoreleasePoolPush();

	va_start(arguments, line);
	format = va_arg(arguments, OFConstantString *);

	if (format != nil)
		message = [[[OFString alloc]
		    initWithFormat: format
			 arguments: arguments] autorelease];

	va_end(arguments);

	[OFStdErr setForegroundColor: [OFColor red]];
	[OFStdErr writeFormat: @"-[%@ %s]: Condition failed: %@%@%@\n",
			       [testCase className], sel_getName(test),
			       check, (message != nil ? @": " : @""),
			       (message != nil ? message : @"")];
	[OFStdErr reset];

	objc_autoreleasePoolPop(pool);

	@throw [OTAssertionFailedException exception];
}
