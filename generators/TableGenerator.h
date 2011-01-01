/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFString.h"

@interface TableGenerator: OFObject
{
	of_unichar_t upperTable[0x110000];
	of_unichar_t lowerTable[0x110000];
	of_unichar_t casefoldingTable[0x110000];
	BOOL upperTableUsed[0x1100];
	BOOL lowerTableUsed[0x1100];
	char casefoldingTableUsed[0x1100];
	size_t upperTableSize;
	size_t lowerTableSize;
	size_t casefoldingTableSize;
}

- (void)readUnicodeDataFileAtPath: (OFString*)path;
- (void)readCaseFoldingFileAtPath: (OFString*)path;
- (void)writeTablesToFileAtPath: (OFString*)file;
- (void)writeHeaderToFileAtPath: (OFString*)file;
@end
