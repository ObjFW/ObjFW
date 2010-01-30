/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import "OFString.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "TableGenerator.h"
#import "copyright.h"

@implementation TableGenerator
- init
{
	self = [super init];

	upper_size = SIZE_MAX;
	lower_size = SIZE_MAX;
	casefolding_size = SIZE_MAX;

	return self;
}

- (void)readUnicodeDataFile: (OFString*)path
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

		splitted = [line splitWithDelimiter: @";"];
		if ([splitted count] != 15) {
			fprintf(stderr, "Invalid line: %s\n", [line cString]);
			exit(1);
		}
		splitted_carray = [splitted cArray];

		codep = [splitted_carray[0] hexadecimalValueAsInteger];
		upper[codep] = [splitted_carray[12] hexadecimalValueAsInteger];
		lower[codep] = [splitted_carray[13] hexadecimalValueAsInteger];

		[pool2 releaseObjects];
	}

	[pool release];
}

- (void)readCaseFoldingFile: (OFString*)path
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

		splitted = [line splitWithDelimiter: @"; "];
		if ([splitted count] != 4) {
			fprintf(stderr, "Invalid line: %s\n", [line cString]);
			exit(1);
		}
		splitted_carray = [splitted cArray];

		if (![splitted_carray[1] isEqual: @"S"] &&
		    ![splitted_carray[1] isEqual: @"C"])
			continue;

		codep = [splitted_carray[0] hexadecimalValueAsInteger];
		casefolding[codep] =
		    [splitted_carray[2] hexadecimalValueAsInteger];

		[pool2 releaseObjects];
	}

	[pool release];
}

- (void)writeTablesToFile: (OFString*)file
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
			if (upper[j] != 0) {
				empty = NO;
				upper_size = i >> 8;
				upper_table_used[upper_size] = YES;
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
				    upper[j], upper[j + 1], upper[j + 2],
				    upper[j + 3], upper[j + 4], upper[j + 5],
				    upper[j + 6], upper[j + 7]]];

			[f writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/* Write lower_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL empty;

		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (lower[j] != 0) {
				empty = NO;
				lower_size = i >> 8;
				lower_table_used[lower_size] = YES;
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
				    lower[j], lower[j + 1], lower[j + 2],
				    lower[j + 3], lower[j + 4], lower[j + 5],
				    lower[j + 6], lower[j + 7]]];

			[f writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/* Write cf_page_%u if it does NOT match lower_page_%u */
	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL empty;

		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (casefolding[j] != 0) {
				empty = (memcmp(lower + i, casefolding + i,
				    256 * sizeof(of_unichar_t)) ? NO : YES);
				casefolding_size = i >> 8;
				casefolding_table_used[casefolding_size] =
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
				    casefolding[j], casefolding[j + 1],
				    casefolding[j + 2], casefolding[j + 3],
				    casefolding[j + 4], casefolding[j + 5],
				    casefolding[j + 6], casefolding[j + 7]]];

			[f writeString: @"};\n\n"];

			[pool2 releaseObjects];
		}
	}

	/*
	 * Those are currently set to the last index.
	 * But from now on, we need the size.
	 */
	upper_size++;
	lower_size++;
	casefolding_size++;

	/* Write of_unicode_upper_table */
	[f writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_upper_table[0x%X] = {\n\t",
	    upper_size]];

	for (i = 0; i < upper_size; i++) {
		if (upper_table_used[i]) {
			[f writeString: [OFString stringWithFormat:
			    @"upper_page_%u", i]];
			[pool2 releaseObjects];
		} else
			[f writeString: @"nop_page"];

		if (i + 1 < upper_size) {
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
	    lower_size]];

	for (i = 0; i < lower_size; i++) {
		if (lower_table_used[i]) {
			[f writeString: [OFString stringWithFormat:
			    @"lower_page_%u", i]];
			[pool2 releaseObjects];
		} else
			[f writeString: @"nop_page"];

		if (i + 1 < lower_size) {
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
	    @"\n\t", casefolding_size]];

	for (i = 0; i < casefolding_size; i++) {
		if (casefolding_table_used[i] == 1) {
			[f writeString: [OFString stringWithFormat:
			    @"cf_page_%u", i]];
			[pool2 releaseObjects];
		} else if (casefolding_table_used[i] == 2) {
			[f writeString: [OFString stringWithFormat:
			    @"lower_page_%u", i]];
		} else
			[f writeString: @"nop_page"];

		if (i + 1 < casefolding_size) {
			if ((i + 1) % 4 == 0)
				[f writeString: @",\n\t"];
			else
				[f writeString: @", "];
		}
	}

	[f writeString: @"\n};\n"];

	[pool release];
}

- (void)writeHeaderToFile: (OFString*)file
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
	    upper_size, lower_size, casefolding_size]];

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
