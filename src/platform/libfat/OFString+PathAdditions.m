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

#import "OFString+PathAdditions.h"
#import "OFArray.h"
#import "OFFileURIHandler.h"

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

		if ([component isEqual: @"/"])
			continue;

		if (!first && ![ret hasSuffix: @"/"])
			[ret appendString: @"/"];

		[ret appendString: component];

		first = false;
	}

	if ([ret hasSuffix: @":"])
		[ret appendString: @"/"];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)isAbsolutePath
{
	return [self containsString: @":/"];
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

	for (i = 0; i < cStringLength; i++) {
		if (cString[i] == '/') {
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

	if ([self hasSuffix: @":/"])
		return self;

	cString = self.UTF8String;
	cStringLength = self.UTF8StringLength;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cString[cStringLength - 1] == '/')
		cStringLength--;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cStringLength - 1 > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	for (i = cStringLength - 1; i >= 0; i--) {
		if (cString[i] == '/') {
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
			      options: OFStringSearchBackwards].location;
	if (pos == OFNotFound || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	ret = [fileName substringFromIndex: pos + 1];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString *)stringByDeletingLastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	const char *cString;
	size_t cStringLength;
	OFString *ret;

	if ([self hasSuffix: @":/"])
		return self;

	cString = self.UTF8String;
	cStringLength = self.UTF8StringLength;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	if (cString[cStringLength - 1] == '/')
		cStringLength--;

	if (cStringLength == 0) {
		objc_autoreleasePoolPop(pool);
		return @"";
	}

	for (size_t i = cStringLength; i >= 1; i--) {
		if (cString[i - 1] == '/') {
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

	if (self.length == 0)
		return [[self copy] autorelease];

	pool = objc_autoreleasePoolPush();
	components = [[self.pathComponents mutableCopy] autorelease];
	fileName = components.lastObject;

	pos = [fileName rangeOfString: @"."
			      options: OFStringSearchBackwards].location;
	if (pos == OFNotFound || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return [[self copy] autorelease];
	}

	fileName = [fileName substringToIndex: pos];
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

			if ([component isEqual: @".."] &&
			    parent != nil && ![parent isEqual: @".."]) {
				[array removeObjectsInRange:
				    OFMakeRange(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	if ([self hasSuffix: @"/"])
		[array addObject: @""];

	ret = [[array componentsJoinedByString: @"/"] retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)stringByAppendingPathComponent: (OFString *)component
{
	if ([self hasSuffix: @"/"])
		return [self stringByAppendingString: component];
	else {
		OFMutableString *ret = [[self mutableCopy] autorelease];

		[ret appendString: @"/"];
		[ret appendString: component];

		[ret makeImmutable];

		return ret;
	}
}

- (OFString *)stringByAppendingPathExtension: (OFString *)extension
{
	if ([self hasSuffix: @"/"]) {
		void *pool = objc_autoreleasePoolPush();
		OFMutableArray *components;
		OFString *fileName, *ret;

		components =
		    [[self.pathComponents mutableCopy] autorelease];
		fileName = [components.lastObject
		    stringByAppendingFormat: @".%@", extension];
		[components replaceObjectAtIndex: components.count - 1
				      withObject: fileName];

		ret = [[OFString pathWithComponents: components] retain];
		objc_autoreleasePoolPop(pool);
		return [ret autorelease];
	} else
		return [self stringByAppendingFormat: @".%@", extension];
}

- (bool)of_isDirectoryPath
{
	return ([self hasSuffix: @"/"] ||
	    [OFFileURIHandler of_directoryExistsAtPath: self]);
}

- (OFString *)of_pathToURIPathWithPercentEncodedHost:
    (OFString **)percentEncodedHost
{
	return [@"/" stringByAppendingString: self];
}

- (OFString *)of_URIPathToPathWithPercentEncodedHost:
    (OFString *)percentEncodedHost
{
	OFString *path = self;

	if (path.length > 1 && [path hasSuffix: @"/"])
		path = [path substringToIndex: path.length - 1];

	return [path substringFromIndex: 1];
}

- (OFString *)of_pathComponentToURIPathComponent
{
	return self;
}
@end
