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

#define COPYRIGHT \
    @"/*\n" \
    @" * Copyright (c) 2008 - 2009\n" \
    @" *   Jonathan Schleifer <js@webkeks.org>\n" \
    @" *\n" \
    @" * All rights reserved.\n" \
    @" *\n" \
    @" * This file is part of libobjfw. It may be distributed under the " \
    @"terms of the\n" \
    @" * Q Public License 1.0, which can be found in the file LICENSE " \
    @"included in\n" \
    @" * the packaging of this file.\n" \
    @" */\n" \
    @"\n"

@interface TableGenerator: OFObject
{
	of_unichar_t upper[0x110000];
	of_unichar_t lower[0x110000];
}

- (void)fillTablesFromFile: (OFString*)file;
- (size_t)writeTable: (of_unichar_t*)table
	    withName: (OFString*)name
	      toFile: (OFString*)file;
- (size_t)writeUpperTableToFile: (OFString*)file;
- (size_t)writeLowerTableToFile: (OFString*)file;
- (void)writeHeaderToFile: (OFString*)file
       withUpperTableSize: (size_t)upper_size
	   lowerTableSize: (size_t)lower_size;
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

		[pool2 releaseObjects];
	}

	[pool release];
}

- (size_t)writeTable: (of_unichar_t*)table
	    withName: (OFString*)name
	      toFile: (OFString*)file
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFAutoreleasePool *pool2;
	OFFile *f = [OFFile fileWithPath: file
				    mode: @"wb"];

	of_unichar_t i, j;
	size_t last_used = SIZE_MAX;
	BOOL table_used[0x1100];

	memset(table_used, NO, 0x1100);

	[f writeString: COPYRIGHT
	    @"#include \"config.h\"\n"
	    @"\n"
	    @"#import \"OFString.h\"\n\n"];

	[f writeString: @"static const of_unichar_t nop_page[0x100] = {};\n\n"];

	for (i = 0; i < 0x110000; i += 0x100) {
		BOOL empty;

		empty = YES;

		for (j = i; j < i + 0x100; j++) {
			if (table[j] != 0) {
				empty = NO;
				last_used = i >> 8;
				table_used[last_used] = YES;
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

	last_used++;

	[f writeString: [OFString stringWithFormat:
	    @"const of_unichar_t* const of_unicode_%s_table[0x%X] = {\n\t",
	    [name cString], last_used]];

	pool2 = [[OFAutoreleasePool alloc] init];
	for (i = 0; i < last_used; i++) {
		if (table_used[i])
			[f writeString: [OFString stringWithFormat: @"page_%d",
								    i]];
		else
			[f writeString: @"nop_page"];

		if ((i + 1) % 4 == 0)
			[f writeString: @",\n\t"];
		else if (i + 1 < last_used)
			[f writeString: @", "];

		[pool2 releaseObjects];
	}

	[f writeString: @"\n};\n"];

	[pool release];
	return last_used;
}

- (size_t)writeUpperTableToFile: (OFString*)file
{
	return [self writeTable: upper
		       withName: @"upper"
			 toFile: file];
}

- (size_t)writeLowerTableToFile: (OFString*)file
{
	return [self writeTable: lower
		       withName: @"lower"
			 toFile: file];
}

- (void)writeHeaderToFile: (OFString*)file
       withUpperTableSize: (size_t)upper_size
	   lowerTableSize: (size_t)lower_size
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFFile *f = [OFFile fileWithPath: file
				    mode: @"wb"];

	[f writeString: COPYRIGHT
	    @"#import \"OFString.h\"\n\n"];

	[f writeString: [OFString stringWithFormat:
	    @"#define OF_UNICODE_UPPER_TABLE_SIZE 0x%X\n"
	    @"#define OF_UNICODE_LOWER_TABLE_SIZE 0x%X\n\n",
	    upper_size, lower_size]];

	[f writeString:
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_upper_table[OF_UNICODE_UPPER_TABLE_SIZE];\n"
	    @"extern const of_unichar_t* const\n"
	    @"    of_unicode_lower_table[OF_UNICODE_LOWER_TABLE_SIZE];\n"];

	[pool release];
}
@end

int
main()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	TableGenerator *tgen = [[[TableGenerator alloc] init] autorelease];
	size_t upper_size, lower_size;

	[tgen fillTablesFromFile: @"UnicodeData.txt"];
	upper_size = [tgen writeUpperTableToFile: @"../src/unicode_upper.m"];
	lower_size = [tgen writeLowerTableToFile: @"../src/unicode_lower.m"];
	[tgen writeHeaderToFile: @"../src/unicode.h"
	     withUpperTableSize: upper_size
		 lowerTableSize: lower_size];

	[pool release];

	return 0;
}
