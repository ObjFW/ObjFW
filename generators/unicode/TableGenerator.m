/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include <string.h>

#import "OFString.h"
#import "OFArray.h"
#import "OFApplication.h"
#import "OFURI.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFHTTPClient.h"
#import "OFFile.h"
#import "OFStdIOStream.h"

#import "OFOutOfRangeException.h"

#import "TableGenerator.h"
#import "copyright.h"

static OFString *const unicodeDataURI =
    @"http://www.unicode.org/Public/UNIDATA/UnicodeData.txt";
static OFString *const caseFoldingURI =
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
		_decompositionTableSize       = SIZE_MAX;
		_decompositionCompatTableSize = SIZE_MAX;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)applicationDidFinishLaunching
{
	OFHTTPRequest *request;

	[OFStdOut writeString: @"Downloading UnicodeData.txt…"];
	_state = stateUnicodeData;
	request = [OFHTTPRequest requestWithURI:
	    [OFURI URIWithString: unicodeDataURI]];
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
		    unsignedLongLongValueWithBase: 16];

		if (codePoint > 0x10FFFF)
			@throw [OFOutOfRangeException exception];

		_uppercaseTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 12] unsignedLongLongValueWithBase: 16];
		_lowercaseTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 13] unsignedLongLongValueWithBase: 16];
		_titlecaseTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 14] unsignedLongLongValueWithBase: 16];

		if ([[components objectAtIndex: 5] length] > 0) {
			OFArray *decomposed = [[components objectAtIndex: 5]
			    componentsSeparatedByString: @" "];
			bool compat = false;
			OFMutableString *string;

			if ([decomposed.firstObject hasPrefix: @"<"]) {
				decomposed = [decomposed objectsInRange:
				    OFMakeRange(1, decomposed.count - 1)];
				compat = true;
			}

			string = [OFMutableString string];

			for (OFString *character in decomposed) {
				OFUnichar unichar = (OFUnichar)[character
				    unsignedLongLongValueWithBase: 16];

				[string appendCharacters: &unichar
						  length: 1];
			}

			[string makeImmutable];

			if (!compat)
				_decompositionTable[codePoint] = [string copy];
			_decompositionCompatTable[codePoint] = [string copy];
		}

		objc_autoreleasePoolPop(pool2);
	}

	[self applyDecompositionRecursivelyForTable: _decompositionTable];
	[self applyDecompositionRecursivelyForTable: _decompositionCompatTable];

	[OFStdOut writeLine: @" done"];

	[OFStdOut writeString: @"Downloading CaseFolding.txt…"];
	_state = stateCaseFolding;
	request = [OFHTTPRequest requestWithURI:
	    [OFURI URIWithString: caseFoldingURI]];
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
		    unsignedLongLongValueWithBase: 16];

		if (codePoint > 0x10FFFF)
			@throw [OFOutOfRangeException exception];

		_caseFoldingTable[codePoint] = (OFUnichar)[[components
		    objectAtIndex: 2] unsignedLongLongValueWithBase: 16];

		objc_autoreleasePoolPop(pool2);
	}

	[OFStdOut writeLine: @" done"];

	[self writeFiles];
}

- (void)applyDecompositionRecursivelyForTable: (OFString *[0x110000])table
{
	bool done;

	do {
		done = true;

		for (OFUnichar i = 0; i < 0x110000; i++) {
			void *pool;
			const OFUnichar *characters;
			size_t length;
			OFMutableString *replacement;
			bool changed = false;

			if (table[i] == nil)
				continue;

			pool = objc_autoreleasePoolPush();
			characters = table[i].characters;
			length = table[i].length;
			replacement = [OFMutableString string];

			for (size_t j = 0; j < length; j++) {
				if (characters[j] > 0x10FFFF)
					@throw [OFOutOfRangeException
					    exception];

				if (table[characters[j]] == nil)
					[replacement
					    appendCharacters: &characters[j]
						      length: 1];
				else {
					[replacement
					    appendString: table[characters[j]]];
					changed = true;
				}
			}

			[replacement makeImmutable];

			if (changed) {
				[table[i] release];
				table[i] = [replacement copy];

				done = false;
			}

			objc_autoreleasePoolPop(pool);
		}
	} while (!done);
}

- (void)writeFiles
{
	OFURI *URI;

	[OFStdOut writeString: @"Writing files…"];

	URI = [OFURI fileURIWithPath: @"../../src/unicode.m"];
	[self writeTablesToFile: URI.fileSystemRepresentation];

	URI = [OFURI fileURIWithPath: @"../../src/unicode.h"];
	[self writeHeaderToFile: URI.fileSystemRepresentation];

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
	    @"#import \"OFString.h\"\n\n"
	    @"static const OFUnichar emptyPage[0x100] = { 0 };\n"
	    @"static const char *emptyDecompositionPage[0x100] = { NULL };\n"
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

	/* Write decompositionPage%u */
	for (OFUnichar i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (OFUnichar j = i; j < i + 0x100; j++) {
			if (_decompositionTable[j] != nil) {
				isEmpty = false;
				_decompositionTableSize = i >> 8;
				_decompositionTableUsed[
				    _decompositionTableSize] = 1;
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeFormat: @"static const char *const "
					   @"decompositionPage%u[0x100] = {\n",
					   i >> 8];

			for (OFUnichar j = i; j < i + 0x100; j++) {
				if ((j - i) % 2 == 0)
					[file writeString: @"\t"];
				else
					[file writeString: @" "];

				if (_decompositionTable[j] != nil) {
					const char *UTF8String =
					    _decompositionTable[j].UTF8String;
					size_t length = _decompositionTable[j]
					    .UTF8StringLength;

					[file writeString: @"\""];

					for (size_t k = 0; k < length; k++)
						[file writeFormat:
						    @"\\x%02X",
						    (uint8_t)UTF8String[k]];

					[file writeString: @"\","];
				} else
					[file writeString: @"NULL,"];

				if ((j - i) % 2 == 1)
					[file writeString: @"\n"];
			}

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write decompCompatPage%u if it does NOT match decompositionPage%u */
	for (OFUnichar i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (OFUnichar j = i; j < i + 0x100; j++) {
			if (_decompositionCompatTable[j] != 0) {
				/*
				 * We bulk-compare pointers via memcmp here.
				 * This is safe, as we always set the same
				 * pointer in both tables if both are the same.
				 */
				isEmpty = !memcmp(_decompositionTable + i,
				    _decompositionCompatTable + i,
				    256 * sizeof(const char *));
				_decompositionCompatTableSize = i >> 8;
				_decompositionCompatTableUsed[
				    _decompositionCompatTableSize] =
				    (isEmpty ? 2 : 1);

				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeFormat: @"static const char *const "
					   @"decompCompatPage%u[0x100] = {\n",
					   i >> 8];

			for (OFUnichar j = i; j < i + 0x100; j++) {
				if ((j - i) % 2 == 0)
					[file writeString: @"\t"];
				else
					[file writeString: @" "];

				if (_decompositionCompatTable[j] != nil) {
					const char *UTF8String =
					    _decompositionCompatTable[j]
					    .UTF8String;
					size_t length =
					    _decompositionCompatTable[j]
					    .UTF8StringLength;

					[file writeString: @"\""];

					for (size_t k = 0; k < length; k++)
						[file writeFormat:
						    @"\\x%02X",
						    (uint8_t)UTF8String[k]];

					[file writeString: @"\","];
				} else
					[file writeString: @"NULL,"];

				if ((j - i) % 2 == 1)
					[file writeString: @"\n"];
			}

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
	_decompositionTableSize++;
	_decompositionCompatTableSize++;

	/* Write OFUnicodeUppercaseTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"OFUnicodeUppercaseTable[0x%X] = {\n\t",
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

	/* Write OFUnicodeLowercaseTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"OFUnicodeLowercaseTable[0x%X] = {\n\t",
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

	/* Write OFUnicodeTitlecaseTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"OFUnicodeTitlecaseTable[0x%X] = {\n\t",
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

	/* Write OFUnicodeCaseFoldingTable */
	[file writeFormat: @"const OFUnichar *const "
			   @"OFUnicodeCaseFoldingTable[0x%X] = {\n\t",
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

	/* Write OFUnicodeDecompositionTable */
	[file writeFormat: @"const char *const "
			   @"*OFUnicodeDecompositionTable[0x%X] = {\n\t",
			   _decompositionTableSize];

	for (OFUnichar i = 0; i < _decompositionTableSize; i++) {
		if (_decompositionTableUsed[i])
			[file writeFormat: @"decompositionPage%u", i];
		else
			[file writeString: @"emptyDecompositionPage"];

		if (i + 1 < _decompositionTableSize) {
			if ((i + 1) % 3 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write OFUnicodeDecompositionCompatTable */
	[file writeFormat: @"const char *const "
			   @"*OFUnicodeDecompositionCompatTable[0x%X] = {"
			   @"\n\t",
			   _decompositionCompatTableSize];

	for (OFUnichar i = 0; i < _decompositionCompatTableSize; i++) {
		if (_decompositionCompatTableUsed[i] == 1)
			[file writeFormat: @"decompCompatPage%u", i];
		else if (_decompositionCompatTableUsed[i] == 2)
			[file writeFormat: @"decompositionPage%u", i];
		else
			[file writeString: @"emptyDecompositionPage"];

		if (i + 1 < _decompositionCompatTableSize) {
			if ((i + 1) % 3 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n"];

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
	    @"#define OFUnicodeUppercaseTableSize 0x%X\n"
	    @"#define OFUnicodeLowercaseTableSize 0x%X\n"
	    @"#define OFUnicodeTitlecaseTableSize 0x%X\n"
	    @"#define OFUnicodeCaseFoldingTableSize 0x%X\n"
	    @"#define OFUnicodeDecompositionTableSize 0x%X\n"
	    @"#define OFUnicodeDecompositionCompatTableSize 0x%X\n\n",
	    _uppercaseTableSize, _lowercaseTableSize, _titlecaseTableSize,
	    _caseFoldingTableSize, _decompositionTableSize,
	    _decompositionCompatTableSize];

	[file writeString:
	    @"#ifdef __cplusplus\n"
	    @"extern \"C\" {\n"
	    @"#endif\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    OFUnicodeUppercaseTable[OFUnicodeUppercaseTableSize];\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    OFUnicodeLowercaseTable[OFUnicodeLowercaseTableSize];\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    OFUnicodeTitlecaseTable[OFUnicodeTitlecaseTableSize];\n"
	    @"extern const OFUnichar *const _Nonnull\n"
	    @"    OFUnicodeCaseFoldingTable[OFUnicodeCaseFoldingTableSize];\n"
	    @"extern const char *const _Nullable *const _Nonnull\n"
	    @"    OFUnicodeDecompositionTable["
	    @"OFUnicodeDecompositionTableSize];\n"
	    @"extern const char *const _Nullable *const _Nonnull\n"
	    @"    OFUnicodeDecompositionCompatTable["
	    @"OFUnicodeDecompositionCompatTableSize];\n"
	    @"#ifdef __cplusplus\n"
	    @"}\n"
	    @"#endif\n"];

	objc_autoreleasePoolPop(pool);
}
@end
