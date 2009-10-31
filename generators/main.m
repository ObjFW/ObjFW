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
#import "CaseFoldingGenerator.h"

int
main()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	UpperLowerGenerator *ulgen;
	CaseFoldingGenerator *cfgen;

	ulgen = [[[UpperLowerGenerator alloc] init] autorelease];
	[ulgen fillTablesFromFile: @"UnicodeData.txt"];
	[ulgen writeUpperTableToFile: @"../src/unicode_upper.m"];
	[ulgen writeLowerTableToFile: @"../src/unicode_lower.m"];
	[ulgen writeHeaderToFile: @"../src/unicode.h"];

	cfgen = [[[CaseFoldingGenerator alloc] init] autorelease];
	[cfgen fillTableFromFile: @"CaseFolding.txt"];
	[cfgen writeTableToFile: @"../src/unicode_casefolding.m"];
	[cfgen appendHeaderToFile: @"../src/unicode.h"];

	[pool release];

	return 0;
}
