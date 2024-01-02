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
	char _uppercaseTableUsed[0x1100];
	char _lowercaseTableUsed[0x1100];
	char _titlecaseTableUsed[0x1100];
	char _caseFoldingTableUsed[0x1100];
	size_t _uppercaseTableSize;
	size_t _lowercaseTableSize;
	size_t _titlecaseTableSize;
	size_t _caseFoldingTableSize;
	enum {
		stateUnicodeData,
		stateCaseFolding
	} _state;
}

- (void)parseUnicodeData: (OFHTTPResponse *)response;
- (void)parseCaseFolding: (OFHTTPResponse *)response;
- (void)writeFiles;
- (void)writeTablesToFile: (OFString *)path;
- (void)writeHeaderToFile: (OFString *)path;
@end
