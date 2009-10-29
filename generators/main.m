/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFAutoreleasePool.h"

#import "UpperLowerGenerator.h"

int
main()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	UpperLowerGenerator *tgen;
	size_t upper_size, lower_size;

	tgen = [[[UpperLowerGenerator alloc] init] autorelease];
	[tgen fillTablesFromFile: @"UnicodeData.txt"];
	upper_size = [tgen writeUpperTableToFile: @"../src/unicode_upper.m"];
	lower_size = [tgen writeLowerTableToFile: @"../src/unicode_lower.m"];
	[tgen writeHeaderToFile: @"../src/unicode.h"
	     withUpperTableSize: upper_size
		 lowerTableSize: lower_size];

	[pool release];

	return 0;
}
