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

#include "config.h"

#include <string.h>

#import "OFString.h"
#import "OFArray.h"
#import "OFApplication.h"
#import "OFURL.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFHTTPClient.h"
#import "OFFile.h"
#import "OFStdIOStream.h"

#import "autorelease.h"

#import "TableGenerator.h"
#import "copyright.h"

#define UNICODE_DATA_URL \
	@"http://www.unicode.org/Public/UNIDATA/UnicodeData.txt"
#define CASE_FOLDING_URL \
	@"http://www.unicode.org/Public/UNIDATA/CaseFolding.txt"

OF_APPLICATION_DELEGATE(TableGenerator)

@implementation TableGenerator
- init
{
	self = [super init];

	uppercaseTableSize   = SIZE_MAX;
	lowercaseTableSize   = SIZE_MAX;
	titlecaseTableSize   = SIZE_MAX;
	casefoldingTableSize = SIZE_MAX;

	return self;
}

- (void)applicationDidFinishLaunching
{
	[self parseUnicodeData];
	[self parseCaseFolding];

	[of_stdout writeString: @"Writing files..."];

	[self writeTablesToFile: @"../src/unicode.m"];
	[self writeHeaderToFile: @"../src/unicode.h"];

	[of_stdout writeLine: @" done"];

	[OFApplication terminate];
}

- (void)parseUnicodeData
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPRequest *request;
	OFHTTPClient *client;
	OFHTTPResponse *response;
	OFString *line;

	[of_stdout writeString: @"Downloading and parsing UnicodeData.txt..."];

	request = [OFHTTPRequest requestWithURL:
	    [OFURL URLWithString: UNICODE_DATA_URL]];
	client = [OFHTTPClient client];
	response = [client performRequest: request];

	while ((line = [response readLine]) != nil) {
		void *pool2;
		OFArray *split;
		OFString **splitObjects;
		of_unichar_t codep;

		if ([line length] == 0)
			continue;

		pool2 = objc_autoreleasePoolPush();

		split = [line componentsSeparatedByString: @";"];
		if ([split count] != 15) {
			of_log(@"Invalid line: %@\n", line);
			[OFApplication terminateWithStatus: 1];
		}
		splitObjects = [split objects];

		codep = (of_unichar_t)[splitObjects[0] hexadecimalValue];
		uppercaseTable[codep] =
		    (of_unichar_t)[splitObjects[12] hexadecimalValue];
		lowercaseTable[codep] =
		    (of_unichar_t)[splitObjects[13] hexadecimalValue];
		titlecaseTable[codep] =
		    (of_unichar_t)[splitObjects[14] hexadecimalValue];

		objc_autoreleasePoolPop(pool2);
	}

	[of_stdout writeLine: @" done"];

	objc_autoreleasePoolPop(pool);
}

- (void)parseCaseFolding
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPRequest *request;
	OFHTTPClient *client;
	OFHTTPResponse *response;
	OFString *line;

	[of_stdout writeString: @"Downloading and parsing CaseFolding.txt..."];

	request = [OFHTTPRequest requestWithURL:
	    [OFURL URLWithString: CASE_FOLDING_URL]];
	client = [OFHTTPClient client];
	response = [client performRequest: request];

	while ((line = [response readLine]) != nil) {
		void *pool2;
		OFArray *split;
		OFString **splitObjects;
		of_unichar_t codep;

		if ([line length] == 0 || [line hasPrefix: @"#"])
			continue;

		pool2 = objc_autoreleasePoolPush();

		split = [line componentsSeparatedByString: @"; "];
		if ([split count] != 4) {
			of_log(@"Invalid line: %s\n", line);
			[OFApplication terminateWithStatus: 1];
		}
		splitObjects = [split objects];

		if (![splitObjects[1] isEqual: @"S"] &&
		    ![splitObjects[1] isEqual: @"C"])
			continue;

		codep = (of_unichar_t)[splitObjects[0] hexadecimalValue];
		casefoldingTable[codep] =
		    (of_unichar_t)[splitObjects[2] hexadecimalValue];

		objc_autoreleasePoolPop(pool2);
	}

	[of_stdout writeLine: @" done"];

	objc_autoreleasePoolPop(pool);
}

- (void)writeTablesToFile: (OFString*)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"wb"];
	of_unichar_t i, j;

	[file writeString: COPYRIGHT
	    @"#include \"config.h\"\n"
	    @"\n"
	    @"#import \"OFString.h\"\n\n"
	    @"static const of_unichar_t nop_page[0x100] = {};\n\n"];

	/* Write uppercase_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (j = i; j < i + 0x100; j++) {
			if (uppercaseTable[j] != 0) {
				isEmpty = false;
				uppercaseTableSize = i >> 8;
				uppercaseTableUsed[uppercaseTableSize] = 1;
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t "
			    @"uppercase_page_%u[0x100] = {\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[file writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    uppercaseTable[j],
				    uppercaseTable[j + 1],
				    uppercaseTable[j + 2],
				    uppercaseTable[j + 3],
				    uppercaseTable[j + 4],
				    uppercaseTable[j + 5],
				    uppercaseTable[j + 6],
				    uppercaseTable[j + 7]]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write lowercase_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (j = i; j < i + 0x100; j++) {
			if (lowercaseTable[j] != 0) {
				isEmpty = false;
				lowercaseTableSize = i >> 8;
				lowercaseTableUsed[lowercaseTableSize] = 1;
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t "
			    @"lowercase_page_%u[0x100] = {\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[file writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    lowercaseTable[j],
				    lowercaseTable[j + 1],
				    lowercaseTable[j + 2],
				    lowercaseTable[j + 3],
				    lowercaseTable[j + 4],
				    lowercaseTable[j + 5],
				    lowercaseTable[j + 6],
				    lowercaseTable[j + 7]]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write titlecase_page_%u if it does NOT match uppercase_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (j = i; j < i + 0x100; j++) {
			if (titlecaseTable[j] != 0) {
				isEmpty = !memcmp(uppercaseTable + i,
				    titlecaseTable + i,
				    256 * sizeof(of_unichar_t));
				titlecaseTableSize = i >> 8;
				titlecaseTableUsed[titlecaseTableSize] =
				    (isEmpty ? 2 : 1);
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t "
			    @"titlecase_page_%u[0x100] = {\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[file writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    titlecaseTable[j],
				    titlecaseTable[j + 1],
				    titlecaseTable[j + 2],
				    titlecaseTable[j + 3],
				    titlecaseTable[j + 4],
				    titlecaseTable[j + 5],
				    titlecaseTable[j + 6],
				    titlecaseTable[j + 7]]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/* Write casefolding_page_%u if it does NOT match lowercase_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		bool isEmpty = true;

		for (j = i; j < i + 0x100; j++) {
			if (casefoldingTable[j] != 0) {
				isEmpty = !memcmp(lowercaseTable + i,
				    casefoldingTable + i,
				    256 * sizeof(of_unichar_t));
				casefoldingTableSize = i >> 8;
				casefoldingTableUsed[casefoldingTableSize] =
				    (isEmpty ? 2 : 1);
				break;
			}
		}

		if (!isEmpty) {
			void *pool2 = objc_autoreleasePoolPush();

			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t "
			    @"casefolding_page_%u[0x100] = {\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[file writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    casefoldingTable[j],
				    casefoldingTable[j + 1],
				    casefoldingTable[j + 2],
				    casefoldingTable[j + 3],
				    casefoldingTable[j + 4],
				    casefoldingTable[j + 5],
				    casefoldingTable[j + 6],
				    casefoldingTable[j + 7]]];

			[file writeString: @"};\n\n"];

			objc_autoreleasePoolPop(pool2);
		}
	}

	/*
	 * Those are currently set to the last index.
	 * But from now on, we need the size.
	 */
	uppercaseTableSize++;
	lowercaseTableSize++;
	titlecaseTableSize++;
	casefoldingTableSize++;

	/* Write of_unicode_uppercase_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_uppercase_table[0x%X] = "
	    @"{\n\t", uppercaseTableSize]];

	for (i = 0; i < uppercaseTableSize; i++) {
		if (uppercaseTableUsed[i]) {
			[file writeString: [OFString stringWithFormat:
			    @"uppercase_page_%u", i]];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < uppercaseTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write of_unicode_lowercase_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_lowercase_table[0x%X] = "
	    @"{\n\t", lowercaseTableSize]];

	for (i = 0; i < lowercaseTableSize; i++) {
		if (lowercaseTableUsed[i]) {
			[file writeString: [OFString stringWithFormat:
			    @"lowercase_page_%u", i]];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < lowercaseTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write of_unicode_titlecase_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_titlecase_table[0x%X] = {"
	    @"\n\t", titlecaseTableSize]];

	for (i = 0; i < titlecaseTableSize; i++) {
		if (titlecaseTableUsed[i] == 1) {
			[file writeString: [OFString stringWithFormat:
			    @"titlecase_page_%u", i]];
		} else if (titlecaseTableUsed[i] == 2) {
			[file writeString: [OFString stringWithFormat:
			    @"uppercase_page_%u", i]];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < titlecaseTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write of_unicode_casefolding_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_casefolding_table[0x%X] = "
	    @"{\n\t", casefoldingTableSize]];

	for (i = 0; i < casefoldingTableSize; i++) {
		if (casefoldingTableUsed[i] == 1) {
			[file writeString: [OFString stringWithFormat:
			    @"casefolding_page_%u", i]];
		} else if (casefoldingTableUsed[i] == 2) {
			[file writeString: [OFString stringWithFormat:
			    @"lowercase_page_%u", i]];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < casefoldingTableSize) {
			if ((i + 1) % 3 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n"];

	objc_autoreleasePoolPop(pool);
}

- (void)writeHeaderToFile: (OFString*)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"wb"];

	[file writeString: COPYRIGHT
	    @"#import \"OFString.h\"\n\n"];

	[file writeString: [OFString stringWithFormat:
	    @"#define OF_UNICODE_UPPERCASE_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_LOWERCASE_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_TITLECASE_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_CASEFOLDING_TABLE_SIZE 0x%X\n\n",
	    uppercaseTableSize, lowercaseTableSize, titlecaseTableSize,
	    casefoldingTableSize]];

	[file writeString:
	    @"#ifdef __cplusplus\n"
	    @"extern \"C\" {\n"
	    @"#endif\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_uppercase_table["
	    @"OF_UNICODE_UPPERCASE_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_lowercase_table["
	    @"OF_UNICODE_LOWERCASE_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_titlecase_table["
	    @"OF_UNICODE_TITLECASE_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_casefolding_table["
	    @"OF_UNICODE_CASEFOLDING_TABLE_SIZE];\n"
	    @"#ifdef __cplusplus\n"
	    @"}\n"
	    @"#endif\n"];

	objc_autoreleasePoolPop(pool);
}
@end
