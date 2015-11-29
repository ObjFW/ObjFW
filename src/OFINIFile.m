/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#include <errno.h>

#import "OFINIFile.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFINICategory.h"
#import "OFINICategory+Private.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

@interface OFINIFile (OF_PRIVATE_CATEGORY)
- (void)OF_parseFile: (OFString*)path
	    encoding: (of_string_encoding_t)encoding;
@end

static bool
isWhitespaceLine(OFString *line)
{
	const char *cString = [line UTF8String];
	size_t i, length = [line UTF8StringLength];

	for (i = 0; i < length; i++) {
		switch (cString[i]) {
		case ' ':
		case '\t':
		case '\n':
		case '\r':
			continue;
		default:
			return false;
		}
	}

	return true;
}

@implementation OFINIFile
+ (instancetype)fileWithPath: (OFString*)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}

+ (instancetype)fileWithPath: (OFString*)path
		    encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithPath: path
				  encoding: encoding] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
{
	return [self initWithPath: path
			 encoding: OF_STRING_ENCODING_UTF_8];
}

- initWithPath: (OFString*)path
      encoding: (of_string_encoding_t)encoding
{
	self = [super init];

	@try {
		_categories = [[OFMutableArray alloc] init];

		[self OF_parseFile: path
			  encoding: encoding];
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

- (OFINICategory*)categoryForName: (OFString*)name
{
	void *pool = objc_autoreleasePoolPush();
	OFINICategory *category;

	for (category in _categories) {
		if ([[category name] isEqual: name]) {
			OFINICategory *ret = [category retain];

			objc_autoreleasePoolPop(pool);

			return [ret autorelease];
		}
	}

	category = [[[OFINICategory alloc] OF_init] autorelease];
	[category setName: name];
	[_categories addObject: category];

	[category retain];

	objc_autoreleasePoolPop(pool);

	return [category autorelease];
}

- (void)OF_parseFile: (OFString*)path
	    encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file;
	OFINICategory *category = nil;
	OFString *line;

	@try {
		file = [OFFile fileWithPath: path
				       mode: @"r"];
	} @catch (OFOpenItemFailedException *e) {
		/* Handle missing file like an empty file */
		if ([e errNo] == ENOENT)
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
			    of_range(1, [line length] - 2)];

			category = [[[OFINICategory alloc]
			    OF_init] autorelease];
			[category setName: categoryName];
			[_categories addObject: category];
		} else {
			if (category == nil)
				@throw [OFInvalidFormatException exception];

			[category OF_parseLine: line];
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (void)writeToFile: (OFString*)path
{
	[self writeToFile: path
		 encoding: OF_STRING_ENCODING_UTF_8];
}

- (void)writeToFile: (OFString*)path
	   encoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"w"];
	bool first = true;

	for (OFINICategory *category in _categories)
		if ([category OF_writeToStream: file
				      encoding: encoding
					 first: first])
			first = false;

	objc_autoreleasePoolPop(pool);
}
@end
