/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import "OFString.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

@interface TableGenerator: OFObject
{
	of_unichar_t upper[0x110000];
	of_unichar_t lower[0x110000];
	of_unichar_t title[0x110000];
}

- (void)fillTablesFromFile: (OFString*)file;
- (void)writeTable: (of_unichar_t*)table
	  withName: (OFString*)name
	    toFile: (OFString*)file;
- (void)writeUpperTableToFile: (OFString*)file;
- (void)writeLowerTableToFile: (OFString*)file;
- (void)writeTitlecaseTableToFile: (OFString*)file;
@end

@implementation TableGenerator
- (void)fillTablesFromFile: (OFString*)file;
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	OFFile *src = [OFFile fileWithPath: file
				      mode: @"rb"];
	OFString *line;

	pool2 = [[OFAutoreleasePool alloc] init];
	while ((line = [src readLine])) {
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
		title[codep] = [splitted_carray[14] hexadecimalValueAsInteger];

		[pool2 releaseObjects];
	}

	[pool release];
}

- (void)writeTable: (of_unichar_t*)table
	  withName: (OFString*)name
	    toFile: (OFString*)file
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFAutoreleasePool *pool2;
	OFFile *f = [OFFile fileWithPath: file
				    mode: @"wb"];

	of_unichar_t i, j;
	BOOL empty;
	BOOL table_used[0x1100];

	memset(table_used, NO, 0x1100);

	[f writeString: @"/*\n"
	    @" * Copyright (c) 2008 - 2009\n"
	    @" *   Jonathan Schleifer <js@webkeks.org>\n"
	    @" *\n"
	    @" * All rights reserved.\n"
	    @" *\n"
	    @" * This file is part of libobjfw. It may be distributed under "
	    @"the terms of the\n"
	    @" * Q Public License 1.0, which can be found in the file LICENSE "
	    @"included in\n"
	    @" * the packaging of this file.\n"
	    @" */\n"
	    @"\n"
	    @"#include \"config.h\"\n"
	    @"\n"
	    @"#import \"OFString.h\"\n\n"];

	[f writeString: @"static const of_unichar_t nop_page[0x100] = {};\n\n"];

	for (i = 0; i < 0x110000; i += 0x100) {
		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (table[j] != 0) {
				empty = NO;
				table_used[i >> 8] = YES;
			}
		}

		if (!empty) {
		       	pool2 = [[OFAutoreleasePool alloc] init];

			[f writeString: [OFString stringWithFormat:
			    @"static const of_unichar_t page_%d[0x100] = {\n",
			    i >> 8]];

			for (j = i; j < i + 0x100; j += 4) {
				[f writeString: [OFString stringWithFormat:
				    @"\t0x%06X, 0x%06X, 0x%06X, 0x%06X,\n",
				    table[j], table[j + 1], table[j + 2],
				    table[j + 3]]];

				[pool2 releaseObjects];
			}

			[f writeString: @"};\n\n"];

			[pool2 release];
		}
	}

	[f writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_%s_table[0x1100] = {\n\t",
	    [name cString]]];

	pool2 = [[OFAutoreleasePool alloc] init];
	for (i = 0; i < 0x1100; i++) {
		if (table_used[i])
			[f writeString: [OFString stringWithFormat: @"page_%d,",
								    i]];
		else
			[f writeString: @"nop_page,"];

		if ((i + 1) % 4)
			[f writeString: @" "];
		else if (i < 0x1100 - 4)
			[f writeString: @"\n\t"];

		[pool2 releaseObjects];
	}

	[f writeString: @"\n};\n"];

	[pool release];
}

- (void)writeUpperTableToFile: (OFString*)file
{
	return [self writeTable: upper
		       withName: @"upper"
			 toFile: file];
}

- (void)writeLowerTableToFile: (OFString*)file
{
	return [self writeTable: lower
		       withName: @"lower"
			 toFile: file];
}

- (void)writeTitlecaseTableToFile: (OFString*)file
{
	return [self writeTable: title
		       withName: @"titlecase"
			 toFile: file];
}
@end

int
main()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	TableGenerator *tgen = [[[TableGenerator alloc] init] autorelease];

	[tgen fillTablesFromFile: @"UnicodeData.txt"];
	[tgen writeUpperTableToFile: @"../src/unicode_upper.m"];
	[tgen writeLowerTableToFile: @"../src/unicode_lower.m"];
	[tgen writeTitlecaseTableToFile: @"../src/unicode_titlecase.m"];

	[pool release];

	return 0;
}
