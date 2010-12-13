/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFString.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFApplication.h"
#import "OFExceptions.h"

#import "TableGenerator.h"
#import "copyright.h"

OF_APPLICATION_DELEGATE(TableGenerator)

@implementation TableGenerator
- init
{
	self = [super init];

	upperTableSize = SIZE_MAX;
	lowerTableSize = SIZE_MAX;
	casefoldingTableSize = SIZE_MAX;

	return self;
}

- (void)applicationDidFinishLaunching
{
	TableGenerator *tgen = [[[TableGenerator alloc] init] autorelease];
	[tgen readUnicodeDataFileAtPath: @"UnicodeData.txt"];
	[tgen readCaseFoldingFileAtPath: @"CaseFolding.txt"];
	[tgen writeTablesToFileAtPath: @"../src/unicode.m"];
	[tgen writeHeaderToFileAtPath: @"../src/unicode.h"];
}

- (void)readUnicodeDataFileAtPath: (OFString*)path
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"rb"];
	OFString *line;

	pool2 = [[OFAutoreleasePool alloc] init];
	while ((line = [file readLine])) {
		OFArray *splitted;
		OFString **splitted_carray;
		of_unichar_t codep;

		splitted = [line componentsSeparatedByString: @";"];
		if ([splitted count] != 15) {
			[of_stderr writeFormat: @"Invalid line: %s\n",
						[line cString]];
			[OFApplication terminateWithStatus: 1];
		}
		splitted_carray = [splitted cArray];

		codep = [splitted_carray[0] hexadecimalValue];
		upperTable[codep] = [splitted_carray[12] hexadecimalValue];
		lowerTable[codep] = [splitted_carray[13] hexadecimalValue];

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
		OFArray *splitted;
		OFString **splitted_carray;
		of_unichar_t codep;

		if ([line characterAtIndex: 0] == '#')
			continue;

		splitted = [line componentsSeparatedByString: @"; "];
		if ([splitted count] != 4) {
			[of_stderr writeFormat: @"Invalid line: %s\n",
						[line cString]];
			[OFApplication terminateWithStatus: 1];
		}
		splitted_carray = [splitted cArray];

		if (![splitted_carray[1] isEqual: @"S"] &&
		    ![splitted_carray[1] isEqual: @"C"])
			continue;

		codep = [splitted_carray[0] hexadecimalValue];
		casefoldingTable[codep] = [splitted_carray[2] hexadecimalValue];

		[pool2 releaseObjects];
	}

	[pool release];
}

- (void)writeTablesToFileAtPath: (OFString*)file
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;

	of_unichar_t i, j;
	OFFile *f = [OFFile fileWithPath: file
				    mode: @"wb"];

	[f writeString: COPYRIGHT
	    @"#include \"config.h\"\n"
	    @"\n"
	    @"#import \"OFString.h\"\n\n"
	    @"static const of_unichar_t nop_page[0x100] = {};\n\n"];

	pool2 = [[OFAutoreleasePool alloc] init];

	/* Write upper_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL empty;

		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (upperTable[j] != 0) {
				empty = NO;
				upperTableSize = i >> 8;
				upperTableUsed[upperTableSize] = YES;
				break;
			}
		}

		if (!empty) {
			[f writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t upper_page_%u[0x100] = "
			    @"{\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[f writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    upperTable[j], upperTable[j + 1],
				    upperTable[j + 2], upperTable[j + 3],
				    upperTable[j + 4], upperTable[j + 5],
				    upperTable[j + 6], upperTable[j + 7]]];

			[f writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/* Write lower_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL empty;

		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (lowerTable[j] != 0) {
				empty = NO;
				lowerTableSize = i >> 8;
				lowerTableUsed[lowerTableSize] = YES;
				break;
			}
		}

		if (!empty) {
			[f writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t lower_page_%u[0x100] = "
			    @"{\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[f writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    lowerTable[j], lowerTable[j + 1],
				    lowerTable[j + 2], lowerTable[j + 3],
				    lowerTable[j + 4], lowerTable[j + 5],
				    lowerTable[j + 6], lowerTable[j + 7]]];

			[f writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/* Write cf_page_%u if it does NOT match lower_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL empty;

		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (casefoldingTable[j] != 0) {
				empty = (memcmp(lowerTable + i,
				    casefoldingTable + i,
				    256 * sizeof(of_unichar_t)) ? NO : YES);
				casefoldingTableSize = i >> 8;
				casefoldingTableUsed[casefoldingTableSize] =
				    (empty ? 2 : 1);
				break;
			}
		}

		if (!empty) {
			[f writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t cf_page_%u[0x100] = {"
			    @"\n", i >> 8]];

			for (j = i; j < i + 0x100; j += 8)
				[f writeString: [OFString stringWithFormat:
				    @"\t%u, %u, %u, %u, %u, %u, %u, %u,\n",
				    casefoldingTable[j],
				    casefoldingTable[j + 1],
				    casefoldingTable[j + 2],
				    casefoldingTable[j + 3],
				    casefoldingTable[j + 4],
				    casefoldingTable[j + 5],
				    casefoldingTable[j + 6],
				    casefoldingTable[j + 7]]];

			[f writeString: @"};\n\n"];

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
	[f writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_upper_table[0x%X] = {\n\t",
	    upperTableSize]];

	for (i = 0; i < upperTableSize; i++) {
		if (upperTableUsed[i]) {
			[f writeString: [OFString stringWithFormat:
			    @"upper_page_%u", i]];
			[pool2 releaseObjects];
		} else
			[f writeString: @"nop_page"];

		if (i + 1 < upperTableSize) {
			if ((i + 1) % 4 == 0)
				[f writeString: @",\n\t"];
			else
				[f writeString: @", "];
		}
	}

	[f writeString: @"\n};\n\n"];

	/* Write of_unicode_lower_table */
	[f writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_lower_table[0x%X] = {\n\t",
	    lowerTableSize]];

	for (i = 0; i < lowerTableSize; i++) {
		if (lowerTableUsed[i]) {
			[f writeString: [OFString stringWithFormat:
			    @"lower_page_%u", i]];
			[pool2 releaseObjects];
		} else
			[f writeString: @"nop_page"];

		if (i + 1 < lowerTableSize) {
			if ((i + 1) % 4 == 0)
				[f writeString: @",\n\t"];
			else
				[f writeString: @", "];
		}
	}

	[f writeString: @"\n};\n\n"];

	/* Write of_unicode_casefolding_table */
	[f writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_casefolding_table[0x%X] = {"
	    @"\n\t", casefoldingTableSize]];

	for (i = 0; i < casefoldingTableSize; i++) {
		if (casefoldingTableUsed[i] == 1) {
			[f writeString: [OFString stringWithFormat:
			    @"cf_page_%u", i]];
			[pool2 releaseObjects];
		} else if (casefoldingTableUsed[i] == 2) {
			[f writeString: [OFString stringWithFormat:
			    @"lower_page_%u", i]];
		} else
			[f writeString: @"nop_page"];

		if (i + 1 < casefoldingTableSize) {
			if ((i + 1) % 4 == 0)
				[f writeString: @",\n\t"];
			else
				[f writeString: @", "];
		}
	}

	[f writeString: @"\n};\n"];

	[pool release];
}

- (void)writeHeaderToFileAtPath: (OFString*)file
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFFile *f = [OFFile fileWithPath: file
				    mode: @"wb"];

	[f writeString: COPYRIGHT
	    @"#import \"OFString.h\"\n\n"];

	[f writeString: [OFString stringWithFormat:
	    @"#define OF_UNICODE_UPPER_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_LOWER_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_CASEFOLDING_TABLE_SIZE 0x%X\n\n",
	    upperTableSize, lowerTableSize, casefoldingTableSize]];

	[f writeString:
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_upper_table[OF_UNICODE_UPPER_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_lower_table[OF_UNICODE_LOWER_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_casefolding_table["
	    @"OF_UNICODE_CASEFOLDING_TABLE_SIZE];\n"];

	[pool release];
}
@end
