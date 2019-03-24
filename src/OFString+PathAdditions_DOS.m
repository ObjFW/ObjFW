/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
		if (component.length == 0)
			continue;

		if ([component isEqual: @"\\"] || [component isEqual: @"/"])
			continue;

		if (!first && ![ret hasSuffix: @"\\"] && ![ret hasSuffix: @"/"])
			[ret appendString: @"\\"];

		[ret appendString: component];

		first = false;
	}

	if ([ret hasSuffix: @":"])
		[ret appendString: @"\\"];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)isAbsolutePath
{
#ifdef OF_WINDOWS
	if ([self hasPrefix: @"\\\\"])
		return true;
#endif

	return ([self containsString: @":\\"] || [self containsString: @":/"]);
}

- (OFArray *)pathComponents
{
	OFMutableArray OF_GENERIC(OFString *) *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	const char *cString = self.UTF8String;
	size_t i, last = 0, cStringLength = self.UTF8StringLength;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return ret;
	}

	if ([self hasPrefix: @"\\\\"]) {
		[ret addObject: @"\\\\"];

		cString += 2;
		cStringLength -= 2;
	}

	for (i = 0; i < cStringLength; i++) {
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
	const char *cString;
	size_t cStringLength;
	ssize_t i;
	OFString *ret;

	if ([self hasSuffix: @":\\"] || [self hasSuffix: @":/"])
		return self;

#ifdef OF_WINDOWS
	if ([self isEqual: @"\\\\"])
		return self;
#endif

	cString = self.UTF8String;
	cStringLength = self.UTF8StringLength;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cString[cStringLength - 1] == '\\' ||
	    cString[cStringLength - 1] == '/')
		cStringLength--;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cStringLength - 1 > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	for (i = cStringLength - 1; i >= 0; i--) {
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
					    length: cStringLength - i];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)pathExtension
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret, *fileName;
	size_t pos;

	fileName = self.lastPathComponent;
	pos = [fileName rangeOfString: @"."
			      options: OF_STRING_SEARCH_BACKWARDS].location;
	if (pos == OF_NOT_FOUND || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	ret = [fileName substringWithRange:
	    of_range(pos + 1, fileName.length - pos - 1)];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString *)stringByDeletingLastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	const char *cString;
	size_t cStringLength;
#ifdef OF_WINDOWS
	bool isUNC = false;
#endif
	OFString *ret;

	if ([self hasSuffix: @":\\"] || [self hasSuffix: @":/"])
		return self;

	cString = self.UTF8String;
	cStringLength = self.UTF8StringLength;

#ifdef OF_WINDOWS
	if ([self hasPrefix: @"\\\\"]) {
		isUNC = true;
		cString += 2;
		cStringLength -= 2;
	}
#endif

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return self;
	}

	if (cString[cStringLength - 1] == '\\' ||
	    cString[cStringLength - 1] == '/')
		cStringLength--;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
#ifdef OF_WINDOWS
		return (isUNC ? @"\\\\" : @"");
#else
		return @"";
#endif
	}

	for (size_t i = cStringLength; i >= 1; i--) {
		if (cString[i - 1] == '\\' || cString[i - 1] == '/') {
#ifdef OF_WINDOWS
			if (isUNC) {
				cString -= 2;
				i += 2;
			}
#endif

			ret = [[OFString alloc] initWithUTF8String: cString
							    length: i - 1];

			objc_autoreleasePoolPop(pool);

			return [ret autorelease];
		}
	}

	objc_autoreleasePoolPop(pool);

#ifdef OF_WINDOWS
	return (isUNC ? @"\\\\" : @".");
#else
	return @".";
#endif
}

- (OFString *)stringByDeletingPathExtension
{
	void *pool;
	OFMutableArray OF_GENERIC(OFString *) *components;
	OFString *ret, *fileName;
	size_t pos;

	if (self.length == 0)
		return [[self copy] autorelease];

	pool = objc_autoreleasePoolPush();
	components = [[self.pathComponents mutableCopy] autorelease];
	fileName = components.lastObject;

	pos = [fileName rangeOfString: @"."
			      options: OF_STRING_SEARCH_BACKWARDS].location;
	if (pos == OF_NOT_FOUND || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	fileName = [fileName substringWithRange: of_range(0, pos)];
	[components replaceObjectAtIndex: components.count - 1
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
#ifdef OF_WINDOWS
	bool isUNC = false;
#endif
	bool done = false;

	if (self.length == 0)
		return @"";

	components = self.pathComponents;

	if (components.count == 1) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	array = [[components mutableCopy] autorelease];

#ifdef OF_WINDOWS
	if ([array.firstObject isEqual: @"\\\\"]) {
		isUNC = true;
		[array removeObjectAtIndex: 0];
	}
#endif

	while (!done) {
		size_t length = array.count;

		done = true;

		for (size_t i = 0; i < length; i++) {
			OFString *component = [array objectAtIndex: i];
			OFString *parent =
			    (i > 0 ? [array objectAtIndex: i - 1] : 0);

			if ([component isEqual: @"."] ||
			   component.length == 0) {
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

#ifdef OF_WINDOWS
	if (isUNC) {
		/*
		 * Only one \ is needed, as the other one is added by
		 * -[componentsJoinedByString:].
		 */
		[array insertObject: @"\\"
			    atIndex: 0];
	}
#endif

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
