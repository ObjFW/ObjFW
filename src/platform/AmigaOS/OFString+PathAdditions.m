/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFFileIRIHandler.h"

#import "OFOutOfRangeException.h"

int _OFString_PathAdditions_reference;

@implementation OFString (PathAdditions)
+ (OFString *)pathWithComponents: (OFArray *)components
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();
	bool firstAfterDevice = true;

	for (OFString *component in components) {
		if (component.length == 0)
			continue;

		if (!firstAfterDevice)
			[ret appendString: @"/"];

		[ret appendString: component];

		if (![component hasSuffix: @":"])
			firstAfterDevice = false;
	}

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)isAbsolutePath
{
	return [self containsString: @":"];
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
			else
				[ret addObject: @"/"];

			last = i + 1;
		} else if (cString[i] == ':') {
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
	 * AmigaOS needs the full parsing to determine the last path component.
	 * This could be optimized by not creating the temporary objects,
	 * though.
	 */
	void *pool = objc_autoreleasePoolPush();
	OFString *ret = self.pathComponents.lastObject;

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
	/*
	 * AmigaOS needs the full parsing to delete the last path component.
	 * This could be optimized, though.
	 */
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFString *) *components = self.pathComponents;
	size_t count = components.count;
	OFString *ret;

	if (count < 2) {
		if ([components.firstObject hasSuffix: @":"]) {
			ret = [components.firstObject retain];
			objc_autoreleasePoolPop(pool);
			return [ret autorelease];
		}

		objc_autoreleasePoolPop(pool);
		return @"";
	}

	components = [components objectsInRange:
	    OFMakeRange(0, components.count - 1)];
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

			if (component.length == 0) {
				[array removeObjectAtIndex: i];

				done = false;
				break;
			}

			if ([component isEqual: @"/"] &&
			    parent != nil && ![parent isEqual: @"/"]) {
				[array removeObjectsInRange:
				    OFMakeRange(i - 1, 2)];

				done = false;
				break;
			}
		}
	}

	ret = [OFString pathWithComponents: array];

	if ([self hasSuffix: @"/"])
		ret = [ret stringByAppendingString: @"/"];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (OFString *)stringByAppendingPathComponent: (OFString *)component
{
	if (self.length == 0)
		return component;

	if ([self hasSuffix: @"/"] || [self hasSuffix: @":"])
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
	return ([self hasSuffix: @"/"] || [self hasSuffix: @":"] ||
	    [OFFileIRIHandler of_directoryExistsAtPath: self]);
}

- (OFString *)of_pathToIRIPathWithPercentEncodedHost:
    (OFString **)percentEncodedHost
{
	OFArray OF_GENERIC(OFString *) *components = self.pathComponents;
	OFMutableString *ret = [OFMutableString string];

	for (OFString *component in components) {
		if (component.length == 0)
			continue;

		if ([component isEqual: @"/"])
			[ret appendString: @"/.."];
		else {
			[ret appendString: @"/"];
			[ret appendString: component];
		}
	}

	[ret makeImmutable];

	return ret;
}

- (OFString *)of_IRIPathToPathWithPercentEncodedHost:
    (OFString *)percentEncodedHost
{
	OFString *path = self;

	if (path.length > 1 && [path hasSuffix: @"/"])
		path = [path substringToIndex: path.length - 1];

	OFMutableArray OF_GENERIC(OFString *) *components;
	size_t count;

	path = [path substringFromIndex: 1];
	components = [[[path
	    componentsSeparatedByString: @"/"] mutableCopy] autorelease];
	count = components.count;

	for (size_t i = 0; i < count; i++) {
		OFString *component = [components objectAtIndex: i];

		if ([component isEqual: @"."]) {
			[components removeObjectAtIndex: i];
			count--;

			i--;
			continue;
		}

		if ([component isEqual: @".."])
			[components replaceObjectAtIndex: i withObject: @"/"];
	}

	return [OFString pathWithComponents: components];
}

- (OFString *)of_pathComponentToIRIPathComponent
{
	return self;
}
@end
