/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFString+PathAdditions.h"
#import "OFArray.h"

#import "OFOutOfRangeException.h"

int _OFString_PathAdditions_reference;

@implementation OFString (PathAdditions)
+ (OFString *)pathWithComponents: (OFArray *)components
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();
	bool first = true;

	for (OFString *component in components) {
		if ([component length] == 0)
			continue;

		if ([component isEqual: @"\\"] || [component isEqual: @"/"])
			continue;

		if (!first && ![ret hasSuffix: @"\\"] && ![ret hasSuffix: @"/"])
			[ret appendString: @"\\"];

		[ret appendString: component];

		first = false;
	}

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)isAbsolutePath
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = [self UTF8String];
	size_t UTF8StringLength = [self UTF8StringLength];
	bool ret = (UTF8StringLength >= 3 && UTF8String[1] == ':' &&
	    (UTF8String[2] == '\\' || UTF8String[2] == '/'));

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFArray *)pathComponents
{
	OFMutableArray OF_GENERIC(OFString *) *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	const char *cString = [self UTF8String];
	size_t i, last = 0, pathCStringLength = [self UTF8StringLength];

	if (pathCStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return ret;
	}

	for (i = 0; i < pathCStringLength; i++) {
		if (cString[i] == '\\' || cString[i] == '/') {
			if (i - last != 0)
				[ret addObject: [OFString
				    stringWithUTF8String: cString + last
						  length: i - last]];

			last = i + 1;
		}
	}
	if (i - last != 0)
		[ret addObject: [OFString stringWithUTF8String: cString + last
							length: i - last]];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFString *)lastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	const char *cString = [self UTF8String];
	size_t pathCStringLength = [self UTF8StringLength];
	ssize_t i;
	OFString *ret;

	if (pathCStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cString[pathCStringLength - 1] == '\\' ||
	    cString[pathCStringLength - 1] == '/')
		pathCStringLength--;

	if (pathCStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (pathCStringLength - 1 > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	for (i = pathCStringLength - 1; i >= 0; i--) {
		if (cString[i] == '\\' || cString[i] == '/') {
			i++;
			break;
		}
	}

	/*
	 * Only one component, but the trailing delimiter might have been
	 * removed, so return a new string anyway.
	 */
	if (i < 0)
		i = 0;

	ret = [[OFString alloc] initWithUTF8String: cString + i
					    length: pathCStringLength - i];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)pathExtension
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret, *fileName;
	size_t pos;

	fileName = [self lastPathComponent];
	pos = [fileName rangeOfString: @"."
			      options: OF_STRING_SEARCH_BACKWARDS].location;
	if (pos == OF_NOT_FOUND || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	ret = [fileName substringWithRange:
	    of_range(pos + 1, [fileName length] - pos - 1)];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString *)stringByDeletingLastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	const char *cString = [self UTF8String];
	size_t pathCStringLength = [self UTF8StringLength];
	OFString *ret;

	if (pathCStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cString[pathCStringLength - 1] == '\\' ||
	    cString[pathCStringLength - 1] == '/')
		pathCStringLength--;

	if (pathCStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	for (size_t i = pathCStringLength; i >= 1; i--) {
		if (cString[i - 1] == '\\' || cString[i - 1] == '/') {
			ret = [[OFString alloc] initWithUTF8String: cString
							    length: i - 1];

			objc_autoreleasePoolPop(pool);

			return [ret autorelease];
		}
	}

	objc_autoreleasePoolPop(pool);

	return @".";
}

- (OFString *)stringByDeletingPathExtension
{
	void *pool;
	OFMutableArray OF_GENERIC(OFString *) *components;
	OFString *ret, *fileName;
	size_t pos;

	if ([self length] == 0)
		return [[self copy] autorelease];

	pool = objc_autoreleasePoolPush();
	components = [[[self pathComponents] mutableCopy] autorelease];
	fileName = [components lastObject];

	pos = [fileName rangeOfString: @"."
			      options: OF_STRING_SEARCH_BACKWARDS].location;
	if (pos == OF_NOT_FOUND || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	fileName = [fileName substringWithRange: of_range(0, pos)];
	[components replaceObjectAtIndex: [components count] - 1
			      withObject: fileName];

	ret = [OFString pathWithComponents: components];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString *)stringByStandardizingPath
{
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFString *) *components;
	OFMutableArray OF_GENERIC(OFString *) *array;
	OFString *ret;
	bool done = false;

	if ([self length] == 0)
		return @"";

	components = [self pathComponents];

	if ([components count] == 1) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	array = [[components mutableCopy] autorelease];

	while (!done) {
		size_t length = [array count];

		done = true;

		for (size_t i = 0; i < length; i++) {
			OFString *component = [array objectAtIndex: i];
			OFString *parent =
			    (i > 0 ? [array objectAtIndex: i - 1] : 0);

			if ([component isEqual: @"."] ||
			   [component length] == 0) {
				[array removeObjectAtIndex: i];

				done = false;
				break;
			}

			if ([component isEqual: @".."] &&
			    parent != nil && ![parent isEqual: @".."]) {
				[array removeObjectsInRange:
				    of_range(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	if ([self hasSuffix: @"\\"] || [self hasSuffix: @"/"])
		[array addObject: @""];

	ret = [[array componentsJoinedByString: @"\\"] retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)stringByAppendingPathComponent: (OFString *)component
{
	if ([self hasSuffix: @"\\"] || [self hasSuffix: @"/"])
		return [self stringByAppendingString: component];
	else {
		OFMutableString *ret = [[self mutableCopy] autorelease];

		[ret appendString: @"\\"];
		[ret appendString: component];

		[ret makeImmutable];

		return ret;
	}
}
@end
