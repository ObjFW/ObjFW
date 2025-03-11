/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include <string.h>

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFIRI.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

#import "TableGenerator.h"
#import "copyright.h"

static OFString *const unicodeDataIRI =
    @"http://www.unicode.org/Public/UNIDATA/UnicodeData.txt";
static OFString *const caseFoldingIRI =
    @"http://www.unicode.org/Public/UNIDATA/CaseFolding.txt";

OF_APPLICATION_DELEGATE(TableGenerator)

@implementation TableGenerator
- (instancetype)init
{
	self = [super init];

	@try {
		_HTTPClient = [[OFHTTPClient alloc] init];
		_HTTPClient.delegate = self;

		_uppercaseTableSize           = SIZE_MAX;
		_lowercaseTableSize           = SIZE_MAX;
		_titlecaseTableSize           = SIZE_MAX;
		_caseFoldingTableSize         = SIZE_MAX;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFHTTPRequest *request;

	[OFStdOut writeString: @"Downloading UnicodeData.txt…"];
	_state = stateUnicodeData;
	request = [OFHTTPRequest requestWithIRI:
	    [OFIRI IRIWithString: unicodeDataIRI]];
	[_HTTPClient asyncPerformRequest: request];
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	  exception: (id)exception
{
	if (exception != nil)
		@throw exception;

	[OFStdOut writeLine: @" done"];

	switch (_state) {
	case stateUnicodeData:
		[self parseUnicodeData: response];
		break;
	case stateCaseFolding:
		[self parseCaseFolding: response];
		break;
	}
}

- (void)parseUnicodeData: (OFHTTPResponse *)response
{
	OFString *line;
	OFHTTPRequest *request;

	[OFStdOut writeString: @"Parsing UnicodeData.txt…"];

	while ((line = [response readLine]) != nil) {
		void *pool2;
		OFArray OF_GENERIC(OFString *) *components;
		OFUnichar codePoint;

		if (line.length == 0)
			continue;

		pool2 = objc_autoreleasePoolPush();

		components = [line componentsSeparatedByString: @";"];
		if (components.count != 15) {
			OFLog(@"Invalid line: %@\n", line);
			[OFApplication terminateWithStatus: 1];
		}

		codePoint = (OFUnichar)[[components objectAtIndex: 0]
		    unsignedLongValueWithBase: 16];

		if (codePoint > 0x10FFFF)
			@throw [OFOutOfRangeException exception];

		_uppercaseTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 12] unsignedLongValueWithBase: 16];
		_lowercaseTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 13] unsignedLongValueWithBase: 16];
		_titlecaseTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 14] unsignedLongValueWithBase: 16];

		objc_autoreleasePoolPop(pool2);
	}

	[OFStdOut writeLine: @" done"];

	[OFStdOut writeString: @"Downloading CaseFolding.txt…"];
	_state = stateCaseFolding;
	request = [OFHTTPRequest requestWithIRI:
	    [OFIRI IRIWithString: caseFoldingIRI]];
	[_HTTPClient asyncPerformRequest: request];
}

- (void)parseCaseFolding: (OFHTTPResponse *)response
{
	OFString *line;

	[OFStdOut writeString: @"Parsing CaseFolding.txt…"];

	while ((line = [response readLine]) != nil) {
		void *pool2;
		OFArray OF_GENERIC(OFString *) *components;
		OFUnichar codePoint;

		if (line.length == 0 || [line hasPrefix: @"#"])
			continue;

		pool2 = objc_autoreleasePoolPush();

		components = [line componentsSeparatedByString: @"; "];
		if (components.count != 4) {
			OFLog(@"Invalid line: %s\n", line);
			[OFApplication terminateWithStatus: 1];
		}

		if (![[components objectAtIndex: 1] isEqual: @"S"] &&
		    ![[components objectAtIndex: 1] isEqual: @"C"])
			continue;

		codePoint = (OFUnichar)[[components objectAtIndex: 0]
		    unsignedLongValueWithBase: 16];

		if (codePoint > 0x10FFFF)
			@throw [OFOutOfRangeException exception];

		_caseFoldingTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 2] unsignedLongValueWithBase: 16];

		objc_autoreleasePoolPop(pool2);
	}

	[OFStdOut writeLine: @" done"];

	[self writeFiles];
}

- (void)writeFiles
{
	OFIRI *IRI;

	[OFStdOut writeString: @"Writing files…"];

	IRI = [OFIRI fileIRIWithPath: @"../../src/unicode.m"];
	[self writeTablesToFile: IRI.fileSystemRepresentation];

	IRI = [OFIRI fileIRIWithPath: @"../../src/unicode.h"];
	[self writeHeaderToFile: IRI.fileSystemRepresentation];

	[OFStdOut writeLine: @" done"];

	[OFApplication terminate];
}

- (void)writeTablesToFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"w"];

	[file writeString: COPYRIGHT
	    @"#include \"config.h\"\n"
	    @"\n"
	    @"#import \"unicode.h\"\n"
	    @"\n"
	    @"static const OFUnichar emptyPage[0x100] = { 0 };\n"
	    @"\n"];

	/* Write uppercasePage%u */
	for (OFUnichar i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (OFUnichar j = i; j < i + 0x100; j++) {
			if (_uppercaseTable[j] != 0) {
				isEmpty = false;
				_uppercaseTableSize = i >> 8;
				_uppercaseTableUsed[_uppercaseTableSize] = 1;
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeFormat: @"static const OFUnichar "
					   @"uppercasePage%u[0x100] = {\n",
					   i >> 8];

			for (OFUnichar j = i; j < i + 0x100; j += 8)
				[file writeFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    _uppercaseTable[j],
				    _uppercaseTable[j + 1],
				    _uppercaseTable[j + 2],
				    _uppercaseTable[j + 3],
				    _uppercaseTable[j + 4],
				    _uppercaseTable[j + 5],
				    _uppercaseTable[j + 6],
				    _uppercaseTable[j + 7]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write lowercasePage%u */
	for (OFUnichar i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (OFUnichar j = i; j < i + 0x100; j++) {
			if (_lowercaseTable[j] != 0) {
				isEmpty = false;
				_lowercaseTableSize = i >> 8;
				_lowercaseTableUsed[_lowercaseTableSize] = 1;
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeFormat: @"static const OFUnichar "
					   @"lowercasePage%u[0x100] = {\n",
					   i >> 8];

			for (OFUnichar j = i; j < i + 0x100; j += 8)
				[file writeFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    _lowercaseTable[j],
				    _lowercaseTable[j + 1],
				    _lowercaseTable[j + 2],
				    _lowercaseTable[j + 3],
				    _lowercaseTable[j + 4],
				    _lowercaseTable[j + 5],
				    _lowercaseTable[j + 6],
				    _lowercaseTable[j + 7]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write titlecasePage%u if it does NOT match uppercasePage%u */
	for (OFUnichar i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (OFUnichar j = i; j < i + 0x100; j++) {
			if (_titlecaseTable[j] != 0) {
				isEmpty = !memcmp(_uppercaseTable + i,
				    _titlecaseTable + i,
				    256 * sizeof(OFUnichar));
				_titlecaseTableSize = i >> 8;
				_titlecaseTableUsed[_titlecaseTableSize] =
				    (isEmpty ? 2 : 1);
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeFormat: @"static const OFUnichar "
					   @"titlecasePage%u[0x100] = {\n",
					   i >> 8];

			for (OFUnichar j = i; j < i + 0x100; j += 8)
				[file writeFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    _titlecaseTable[j],
				    _titlecaseTable[j + 1],
				    _titlecaseTable[j + 2],
				    _titlecaseTable[j + 3],
				    _titlecaseTable[j + 4],
				    _titlecaseTable[j + 5],
				    _titlecaseTable[j + 6],
				    _titlecaseTable[j + 7]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write caseFoldingPage%u if it does NOT match lowercasePage%u */
	for (OFUnichar i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (OFUnichar j = i; j < i + 0x100; j++) {
			if (_caseFoldingTable[j] != 0) {
				isEmpty = !memcmp(_lowercaseTable + i,
				    _caseFoldingTable + i,
				    256 * sizeof(OFUnichar));
				_caseFoldingTableSize = i >> 8;
				_caseFoldingTableUsed[_caseFoldingTableSize] =
				    (isEmpty ? 2 : 1);
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeFormat: @"static const OFUnichar "
					   @"caseFoldingPage%u[0x100] = {\n",
					   i >> 8];

			for (OFUnichar j = i; j < i + 0x100; j += 8)
				[file writeFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    _caseFoldingTable[j],
				    _caseFoldingTable[j + 1],
				    _caseFoldingTable[j + 2],
				    _caseFoldingTable[j + 3],
				    _caseFoldingTable[j + 4],
				    _caseFoldingTable[j + 5],
				    _caseFoldingTable[j + 6],
				    _caseFoldingTable[j + 7]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/*
	 * Those are currently set to the last index.
	 * But from now on, we need the size.
	 */
	_uppercaseTableSize++;
	_lowercaseTableSize++;
	_titlecaseTableSize++;
	_caseFoldingTableSize++;

	/* Write _OFUnicodeUppercaseTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"_OFUnicodeUppercaseTable[0x%X] = {\n\t",
			   _uppercaseTableSize];

	for (OFUnichar i = 0; i < _uppercaseTableSize; i++) {
		if (_uppercaseTableUsed[i])
			[file writeFormat: @"uppercasePage%u", i];
		else
			[file writeString: @"emptyPage"];

		if (i + 1 < _uppercaseTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write _OFUnicodeLowercaseTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"_OFUnicodeLowercaseTable[0x%X] = {\n\t",
			   _lowercaseTableSize];

	for (OFUnichar i = 0; i < _lowercaseTableSize; i++) {
		if (_lowercaseTableUsed[i])
			[file writeFormat: @"lowercasePage%u", i];
		else
			[file writeString: @"emptyPage"];

		if (i + 1 < _lowercaseTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write _OFUnicodeTitlecaseTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"_OFUnicodeTitlecaseTable[0x%X] = {\n\t",
			   _titlecaseTableSize];

	for (OFUnichar i = 0; i < _titlecaseTableSize; i++) {
		if (_titlecaseTableUsed[i] == 1)
			[file writeFormat: @"titlecasePage%u", i];
		else if (_titlecaseTableUsed[i] == 2)
			[file writeFormat: @"uppercasePage%u", i];
		else
			[file writeString: @"emptyPage"];

		if (i + 1 < _titlecaseTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write _OFUnicodeCaseFoldingTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"_OFUnicodeCaseFoldingTable[0x%X] = {\n\t",
			   _caseFoldingTableSize];

	for (OFUnichar i = 0; i < _caseFoldingTableSize; i++) {
		if (_caseFoldingTableUsed[i] == 1)
			[file writeFormat: @"caseFoldingPage%u", i];
		else if (_caseFoldingTableUsed[i] == 2)
			[file writeFormat: @"lowercasePage%u", i];
		else
			[file writeString: @"emptyPage"];

		if (i + 1 < _caseFoldingTableSize) {
			if ((i + 1) % 3 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	objc_autoreleasePoolPop(pool);
}

- (void)writeHeaderToFile: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"w"];

	[file writeString: COPYRIGHT
	    @"#import \"OFString.h\"\n\n"];

	[file writeFormat:
	    @"#define _OFUnicodeUppercaseTableSize 0x%X\n"
	    @"#define _OFUnicodeLowercaseTableSize 0x%X\n"
	    @"#define _OFUnicodeTitlecaseTableSize 0x%X\n"
	    @"#define _OFUnicodeCaseFoldingTableSize 0x%X\n\n",
	    _uppercaseTableSize, _lowercaseTableSize, _titlecaseTableSize,
	    _caseFoldingTableSize];

	[file writeString:
	    @"#ifdef __cplusplus\n"
	    @"extern \"C\" {\n"
	    @"#endif\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    _OFUnicodeUppercaseTable[_OFUnicodeUppercaseTableSize] "
	    @"OF_VISIBILITY_HIDDEN;\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    _OFUnicodeLowercaseTable[_OFUnicodeLowercaseTableSize] "
	    @"OF_VISIBILITY_HIDDEN;\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    _OFUnicodeTitlecaseTable[_OFUnicodeTitlecaseTableSize] "
	    @"OF_VISIBILITY_HIDDEN;\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    _OFUnicodeCaseFoldingTable[_OFUnicodeCaseFoldingTableSize]\n"
	    @"    OF_VISIBILITY_HIDDEN;\n"
	    @"#ifdef __cplusplus\n"
	    @"}\n"
	    @"#endif\n"];

	objc_autoreleasePoolPop(pool);
}
@end
