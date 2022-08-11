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

#include <errno.h>

#import "OFINIFile.h"
#import "OFArray.h"
#import "OFINICategory+Private.h"
#import "OFINICategory.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFURLHandler.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

OF_DIRECT_MEMBERS
@interface OFINIFile ()
- (void)of_parseURL: (OFURL *)URL encoding: (OFStringEncoding)encoding;
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
@synthesize categories = _categories;

+ (instancetype)fileWithURL: (OFURL *)URL
{
	return [[[self alloc] initWithURL: URL] autorelease];
}

+ (instancetype)fileWithURL: (OFURL *)URL encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithURL: URL encoding: encoding] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithURL: (OFURL *)URL
{
	return [self initWithURL: URL encoding: OFStringEncodingAutodetect];
}

- (instancetype)initWithURL: (OFURL *)URL encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		_categories = [[OFMutableArray alloc] init];

		[self of_parseURL: URL encoding: encoding];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_categories release];

	[super dealloc];
}

- (OFINICategory *)categoryForName: (OFString *)name
{
	void *pool = objc_autoreleasePoolPush();
	OFINICategory *category;

	for (category in _categories)
		if ([category.name isEqual: name])
			return category;

	category = [[[OFINICategory alloc] of_initWithName: name] autorelease];
	[_categories addObject: category];

	objc_autoreleasePoolPop(pool);

	return category;
}

- (void)of_parseURL: (OFURL *)URL encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *file;
	OFINICategory *category = nil;
	OFString *line;

	@try {
		file = [OFURLHandler openItemAtURL: URL mode: @"r"];
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
			OFString *categoryName;

			if (![line hasSuffix: @"]"])
				@throw [OFInvalidFormatException exception];

			categoryName = [line substringWithRange:
			    OFRangeMake(1, line.length - 2)];
			category = [[[OFINICategory alloc]
			    of_initWithName: categoryName] autorelease];
			[_categories addObject: category];
		} else {
			if (category == nil)
				@throw [OFInvalidFormatException exception];

			[category of_parseLine: line];
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (void)writeToURL: (OFURL *)URL
{
	[self writeToURL: URL encoding: OFStringEncodingUTF8];
}

- (void)writeToURL: (OFURL *)URL encoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *file = [OFURLHandler openItemAtURL: URL mode: @"w"];
	bool first = true;

	for (OFINICategory *category in _categories)
		if ([category of_writeToStream: file
				      encoding: encoding
					 first: first])
			first = false;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   self.class, _categories];
}
@end
