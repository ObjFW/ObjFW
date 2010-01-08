/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

@interface TableGenerator: OFObject
{
	int16_t upper[0x110000];
	int16_t lower[0x110000];
	of_unichar_t casefolding[0x110000];
	BOOL upper_table_used[0x1100];
	BOOL lower_table_used[0x1100];
	BOOL casefolding_table_used[0x1100];
	size_t upper_size;
	size_t lower_size;
	size_t casefolding_size;
}

- (void)readUnicodeDataFile: (OFString*)path;
- (void)readCaseFoldingFile: (OFString*)path;
- (void)writeTablesToFile: (OFString*)file;
- (void)writeHeaderToFile: (OFString*)file;
@end
