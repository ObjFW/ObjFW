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

#include <errno.h>

#import "OFINIFile.h"
#import "OFArray.h"
#import "OFINISection.h"
#import "OFINISection+Private.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFStream.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

OF_DIRECT_MEMBERS
@interface OFINIFile ()
- (void)of_parseIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding;
@end

static bool
isWhitespaceLine(OFString *line)
{
	const char *cString = line.UTF8String;
	size_t length = line.UTF8StringLength;

	for (size_t i = 0; i < length; i++)
		if (!OFASCIIIsSpace(cString[i]))
			return false;

	return true;
}

@implementation OFINIFile
@synthesize sections = _sections;

+ (instancetype)fileWithIRI: (OFIRI *)IRI
{
	return objc_autoreleaseReturnValue([[self alloc] initWithIRI: IRI]);
}

+ (instancetype)fileWithIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithIRI: IRI
			     encoding: encoding]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithIRI: (OFIRI *)IRI
{
	return [self initWithIRI: IRI encoding: OFStringEncodingAutodetect];
}

- (instancetype)initWithIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		OFINISection *section = objc_autorelease(
		    [[OFINISection alloc] of_initWithName: @""]);
		_sections = [[OFMutableArray alloc] initWithObject: section];

		[self of_parseIRI: IRI encoding: encoding];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_sections);

	[super dealloc];
}

- (OFArray OF_GENERIC(OFINISection *) *)categories
{
	return self.sections;
}

- (OFINISection *)sectionForName: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	OFINISection *section;

	for (section in _sections)
		if ([section.name isEqual: name])
			return section;

	section = objc_autorelease(
	    [[OFINISection alloc] of_initWithName: name]);
	[_sections addObject: section];

	objc_autoreleasePoolPop(pool);

	return section;
}

- (OFINISection *)categoryForName: (OFString *)name
{
	return [self sectionForName: name];
}

- (void)of_parseIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *file;
	OFINISection *section = nil;
	OFString *line;

	if (encoding == OFStringEncodingAutodetect)
		encoding = OFStringEncodingUTF8;

	@try {
		file = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		/* Handle missing file like an empty file */
		if (e.errNo == ENOENT)
			return;

		@throw e;
	}

	while ((line = [file readLineWithEncoding: encoding]) != nil) {
		if (isWhitespaceLine(line))
			continue;

		if ([line hasPrefix: @"["]) {
			OFString *sectionName;

			if (![line hasSuffix: @"]"])
				@throw [OFInvalidFormatException exception];

			sectionName = [line substringWithRange:
			    OFMakeRange(1, line.length - 2)];
			if (sectionName.length == 0)
				@throw [OFInvalidFormatException exception];

			section = objc_autorelease([[OFINISection alloc]
			    of_initWithName: sectionName]);
			[_sections addObject: section];
		} else {
			if (section == nil)
				section = [self sectionForName: @""];

			[section of_parseLine: line];
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (void)writeToIRI: (OFIRI *)IRI
{
	[self writeToIRI: IRI encoding: OFStringEncodingUTF8];
}

- (void)writeToIRI: (OFIRI *)IRI encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *file = [OFIRIHandler openItemAtIRI: IRI mode: @"w"];
	bool first = true;

	for (OFINISection *section in _sections)
		if ([section of_writeToStream: file
				     encoding: encoding
					first: first])
			first = false;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   self.class, _sections];
}
@end
