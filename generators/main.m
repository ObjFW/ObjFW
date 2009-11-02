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

#import "TableGenerator.h"

int
main()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	TableGenerator *tgen;

	tgen = [[[TableGenerator alloc] init] autorelease];
	[tgen readUnicodeDataFile: @"UnicodeData.txt"];
	[tgen readCaseFoldingFile: @"CaseFolding.txt"];
	[tgen writeTablesToFile: @"../src/unicode.m"];
	[tgen writeHeaderToFile: @"../src/unicode.h"];

	[pool release];

	return 0;
}
