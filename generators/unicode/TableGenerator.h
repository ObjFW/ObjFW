/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFHTTPClient.h"

@class OFString;

@interface TableGenerator: OFObject <OFApplicationDelegate,
    OFHTTPClientDelegate>
{
	OFHTTPClient *_HTTPClient;
	OFUnichar _uppercaseTable[0x110000];
	OFUnichar _lowercaseTable[0x110000];
	OFUnichar _titlecaseTable[0x110000];
	OFUnichar _caseFoldingTable[0x110000];
	OFString *_decompositionTable[0x110000];
	OFString *_decompositionCompatTable[0x110000];
	char _uppercaseTableUsed[0x1100];
	char _lowercaseTableUsed[0x1100];
	char _titlecaseTableUsed[0x1100];
	char _caseFoldingTableUsed[0x1100];
	char _decompositionTableUsed[0x1100];
	char _decompositionCompatTableUsed[0x1100];
	size_t _uppercaseTableSize;
	size_t _lowercaseTableSize;
	size_t _titlecaseTableSize;
	size_t _caseFoldingTableSize;
	size_t _decompositionTableSize;
	size_t _decompositionCompatTableSize;
	enum {
		stateUnicodeData,
		stateCaseFolding
	} _state;
}

- (void)parseUnicodeData: (OFHTTPResponse *)response;
- (void)parseCaseFolding: (OFHTTPResponse *)response;
- (void)applyDecompositionRecursivelyForTable: (OFString *[0x110000])table;
- (void)writeFiles;
- (void)writeTablesToFile: (OFString *)path;
- (void)writeHeaderToFile: (OFString *)path;
@end
