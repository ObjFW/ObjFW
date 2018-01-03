/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFHTTPClient.h"

@class OFString;

@interface TableGenerator: OFObject <OFHTTPClientDelegate>
{
	OFHTTPClient *_HTTPClient;
	of_unichar_t _uppercaseTable[0x110000];
	of_unichar_t _lowercaseTable[0x110000];
	of_unichar_t _titlecaseTable[0x110000];
	of_unichar_t _casefoldingTable[0x110000];
	OFString *_decompositionTable[0x110000];
	OFString *_decompositionCompatTable[0x110000];
	char _uppercaseTableUsed[0x1100];
	char _lowercaseTableUsed[0x1100];
	char _titlecaseTableUsed[0x1100];
	char _casefoldingTableUsed[0x1100];
	char _decompositionTableUsed[0x1100];
	char _decompositionCompatTableUsed[0x1100];
	size_t _uppercaseTableSize;
	size_t _lowercaseTableSize;
	size_t _titlecaseTableSize;
	size_t _casefoldingTableSize;
	size_t _decompositionTableSize;
	size_t _decompositionCompatTableSize;
}

- (void)parseUnicodeData: (OFHTTPResponse *)response;
- (void)parseCaseFolding: (OFHTTPResponse *)response;
- (void)applyDecompositionRecursivelyForTable: (OFString *[0x110000])table;
- (void)writeFiles;
- (void)writeTablesToFile: (OFString *)path;
- (void)writeHeaderToFile: (OFString *)path;
@end
