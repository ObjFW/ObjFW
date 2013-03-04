/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFObject.h"

@class OFString;

@interface TableGenerator: OFObject
{
	of_unichar_t uppercaseTable[0x110000];
	of_unichar_t lowercaseTable[0x110000];
	of_unichar_t titlecaseTable[0x110000];
	of_unichar_t casefoldingTable[0x110000];
	char uppercaseTableUsed[0x1100];
	char lowercaseTableUsed[0x1100];
	char titlecaseTableUsed[0x1100];
	char casefoldingTableUsed[0x1100];
	size_t uppercaseTableSize;
	size_t lowercaseTableSize;
	size_t titlecaseTableSize;
	size_t casefoldingTableSize;
}

- (void)parseUnicodeData;
- (void)parseCaseFolding;
- (void)writeTablesToFile: (OFString*)path;
- (void)writeHeaderToFile: (OFString*)path;
@end
