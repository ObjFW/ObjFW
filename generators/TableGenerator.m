/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFApplication.h"

#import "TableGenerator.h"
#import "copyright.h"

OF_APPLICATION_DELEGATE(TableGenerator)

@implementation TableGenerator
- init
{
	self = [super init];

	upperTableSize	     = SIZE_MAX;
	lowerTableSize	     = SIZE_MAX;
	casefoldingTableSize = SIZE_MAX;

	return self;
}

- (void)applicationDidFinishLaunching
{
	TableGenerator *generator = [[[TableGenerator alloc] init] autorelease];

	[generator readUnicodeDataFileAtPath: @"UnicodeData.txt"];
	[generator readCaseFoldingFileAtPath: @"CaseFolding.txt"];

	[generator writeTablesToFileAtPath: @"../src/unicode.m"];
	[generator writeHeaderToFileAtPath: @"../src/unicode.h"];
}

- (void)readUnicodeDataFileAtPath: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"rb"];
	OFString *line;

	pool2 = [[OFAutoreleasePool alloc] init];
	while ((line = [file readLine])) {
		OFArray *split;
		OFString **splitCArray;
		of_unichar_t codep;

		split = [line componentsSeparatedByString: @";"];
		if ([split count] != 15) {
			of_log(@"Invalid line: %@\n", line);
			[OFApplication terminateWithStatus: 1];
		}
		splitCArray = [split cArray];

		codep = (of_unichar_t)[splitCArray[0] hexadecimalValue];
		upperTable[codep] =
		    (of_unichar_t)[splitCArray[12] hexadecimalValue];
		lowerTable[codep] =
		    (of_unichar_t)[splitCArray[13] hexadecimalValue];

		[pool2 releaseObjects];
	}

	[pool release];
}

- (void)readCaseFoldingFileAtPath: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"rb"];
	OFString *line;

	pool2 = [[OFAutoreleasePool alloc] init];
	while ((line = [file readLine])) {
		OFArray *split;
		OFString **splitCArray;
		of_unichar_t codep;

		if ([line characterAtIndex: 0] == '#')
			continue;

		split = [line componentsSeparatedByString: @"; "];
		if ([split count] != 4) {
			of_log(@"Invalid line: %s\n", line);
			[OFApplication terminateWithStatus: 1];
		}
		splitCArray = [split cArray];

		if (![splitCArray[1] isEqual: @"S"] &&
		    ![splitCArray[1] isEqual: @"C"])
			continue;

		codep = (of_unichar_t)[splitCArray[0] hexadecimalValue];
		casefoldingTable[codep] =
		    (of_unichar_t)[splitCArray[2] hexadecimalValue];

		[pool2 releaseObjects];
	}

	[pool release];
}

- (void)writeTablesToFileAtPath: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;

	of_unichar_t i, j;
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"wb"];

	[file writeString: COPYRIGHT
	    @"#include \"config.h\"\n"
	    @"\n"
	    @"#import \"OFString.h\"\n\n"
	    @"static const of_unichar_t nop_page[0x100] = {};\n\n"];

	pool2 = [[OFAutoreleasePool alloc] init];

	/* Write upper_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL isEmpty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (upperTable[j] != 0) {
				isEmpty = NO;
				upperTableSize = i >> 8;
				upperTableUsed[upperTableSize] = YES;
				break;
			}
		}

		if (!isEmpty) {
			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t upper_page_%u[0x100] = "
			    @"{\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[file writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    upperTable[j], upperTable[j + 1],
				    upperTable[j + 2], upperTable[j + 3],
				    upperTable[j + 4], upperTable[j + 5],
				    upperTable[j + 6], upperTable[j + 7]]];

			[file writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/* Write lower_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL isEmpty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (lowerTable[j] != 0) {
				isEmpty = NO;
				lowerTableSize = i >> 8;
				lowerTableUsed[lowerTableSize] = YES;
				break;
			}
		}

		if (!isEmpty) {
			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t lower_page_%u[0x100] = "
			    @"{\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[file writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    lowerTable[j], lowerTable[j + 1],
				    lowerTable[j + 2], lowerTable[j + 3],
				    lowerTable[j + 4], lowerTable[j + 5],
				    lowerTable[j + 6], lowerTable[j + 7]]];

			[file writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/* Write cf_page_%u if it does NOT match lower_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL isEmpty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (casefoldingTable[j] != 0) {
				isEmpty = (memcmp(lowerTable + i,
				    casefoldingTable + i,
				    256 * sizeof(of_unichar_t)) ? NO : YES);
				casefoldingTableSize = i >> 8;
				casefoldingTableUsed[casefoldingTableSize] =
				    (isEmpty ? 2 : 1);
				break;
			}
		}

		if (!isEmpty) {
			[file writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t cf_page_%u[0x100] = {"
			    @"\n", i >> 8]];

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

			[pool2 releaseObjects];
		}
	}

	/*
	 * Those are currently set to the last index.
	 * But from now on, we need the size.
	 */
	upperTableSize++;
	lowerTableSize++;
	casefoldingTableSize++;

	/* Write of_unicode_upper_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_upper_table[0x%X] = {\n\t",
	    upperTableSize]];

	for (i = 0; i < upperTableSize; i++) {
		if (upperTableUsed[i]) {
			[file writeString: [OFString stringWithFormat:
			    @"upper_page_%u", i]];
			[pool2 releaseObjects];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < upperTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write of_unicode_lower_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_lower_table[0x%X] = {\n\t",
	    lowerTableSize]];

	for (i = 0; i < lowerTableSize; i++) {
		if (lowerTableUsed[i]) {
			[file writeString: [OFString stringWithFormat:
			    @"lower_page_%u", i]];
			[pool2 releaseObjects];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < lowerTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n\n"];

	/* Write of_unicode_casefolding_table */
	[file writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_casefolding_table[0x%X] = {"
	    @"\n\t", casefoldingTableSize]];

	for (i = 0; i < casefoldingTableSize; i++) {
		if (casefoldingTableUsed[i] == 1) {
			[file writeString: [OFString stringWithFormat:
			    @"cf_page_%u", i]];
			[pool2 releaseObjects];
		} else if (casefoldingTableUsed[i] == 2) {
			[file writeString: [OFString stringWithFormat:
			    @"lower_page_%u", i]];
		} else
			[file writeString: @"nop_page"];

		if (i + 1 < casefoldingTableSize) {
			if ((i + 1) % 4 == 0)
				[file writeString: @",\n\t"];
			else
				[file writeString: @", "];
		}
	}

	[file writeString: @"\n};\n"];

	[pool release];
}

- (void)writeHeaderToFileAtPath: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"wb"];

	[file writeString: COPYRIGHT
	    @"#import \"OFString.h\"\n\n"];

	[file writeString: [OFString stringWithFormat:
	    @"#define OF_UNICODE_UPPER_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_LOWER_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_CASEFOLDING_TABLE_SIZE 0x%X\n\n",
	    upperTableSize, lowerTableSize, casefoldingTableSize]];

	[file writeString:
	    @"#ifdef __cplusplus\n"
	    @"extern \"C\" {\n"
	    @"#endif\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_upper_table[OF_UNICODE_UPPER_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_lower_table[OF_UNICODE_LOWER_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_casefolding_table["
	    @"OF_UNICODE_CASEFOLDING_TABLE_SIZE];\n"
	    @"#ifdef __cplusplus\n"
	    @"}\n"
	    @"#endif\n"];

	[pool release];
}
@end
