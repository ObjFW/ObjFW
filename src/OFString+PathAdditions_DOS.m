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

		if (!first && ![ret hasSuffix: @":"] &&
		    ([component isEqual: @"\\"] || [component isEqual: @"/"]))
			continue;

		if (!first && ![ret hasSuffix: @"\\"] &&
		    ![ret hasSuffix: @"/"] && ![ret hasSuffix: @":"])
			[ret appendString: @"\\"];

		[ret appendString: component];

		first = false;
	}

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
	bool isUNC = false;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return ret;
	}

	if ([self hasPrefix: @"\\\\"]) {
		isUNC = true;
		[ret addObject: @"\\\\"];

		cString += 2;
		cStringLength -= 2;
	}

	for (i = 0; i < cStringLength; i++) {
		if (cString[i] == '\\' || cString[i] == '/') {
			if (i == 0)
				[ret addObject: [OFString
				    stringWithUTF8String: cString
						  length: 1]];
			else if (i - last != 0)
				[ret addObject: [OFString
				    stringWithUTF8String: cString + last
						  length: i - last]];

			last = i + 1;
		} else if (!isUNC && cString[i] == ':') {
			if (i + 1 < cStringLength &&
			    (cString[i + 1] == '\\' || cString[i + 1] == '/'))
				i++;

			[ret addObject: [OFString
			    stringWithUTF8String: cString + last
					  length: i - last + 1]];

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
	/*
	 * Windows/DOS need the full parsing to determine the last path
	 * component. This could be optimized by not creating the temporary
	 * objects, though.
	 */
	void *pool = objc_autoreleasePoolPush();
	OFString *ret = self.pathComponents.lastObject;

	if (ret == nil) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	[ret retain];
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
	/*
	 * Windows/DOS need the full parsing to delete the last path component.
	 * This could be optimized, though.
	 */
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFString *) *components = self.pathComponents;
	size_t count = components.count;
	OFString *ret;

	if (count == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (count == 1) {
		OFString *firstComponent = components.firstObject;

		if ([firstComponent hasSuffix: @":"] ||
		    [firstComponent hasSuffix: @":\\"] ||
		    [firstComponent hasSuffix: @":/"] ||
		    [firstComponent hasPrefix: @"\\"]) {
			ret = [firstComponent retain];
			objc_autoreleasePoolPop(pool);
			return [ret autorelease];
		}

		objc_autoreleasePoolPop(pool);
		return @".";
	}

	components = [components objectsInRange:
	    of_range(0, components.count - 1)];
	ret = [OFString pathWithComponents: components];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
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
	bool done = false;

	if (self.length == 0)
		return @"";

	components = self.pathComponents;

	if (components.count == 1) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	array = [[components mutableCopy] autorelease];

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

			if ([component isEqual: @".."] && parent != nil &&
			    ![parent isEqual: @".."] &&
			    ![parent hasSuffix: @":"] &&
			    ![parent hasSuffix: @":\\"] &&
			    ![parent hasSuffix: @"://"] &&
			    (![parent hasPrefix: @"\\"] || i != 1)) {
				[array removeObjectsInRange:
				    of_range(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	ret = [[OFString pathWithComponents: array] retain];

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
