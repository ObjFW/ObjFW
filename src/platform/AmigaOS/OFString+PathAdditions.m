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

	objc_retain(ret);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
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

	objc_retain(ret);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
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
			ret = objc_retain(components.firstObject);
			objc_autoreleasePoolPop(pool);
			return objc_autoreleaseReturnValue(ret);
		}

		objc_autoreleasePoolPop(pool);
		return @"";
	}

	components = [components objectsInRange:
	    OFMakeRange(0, components.count - 1)];
	ret = [OFString pathWithComponents: components];

	objc_retain(ret);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
}

- (OFString *)stringByDeletingPathExtension
{
	void *pool;
	OFMutableArray OF_GENERIC(OFString *) *components;
	OFString *ret, *fileName;
	size_t pos;

	if (self.length == 0)
		return objc_autoreleaseReturnValue([self copy]);

	pool = objc_autoreleasePoolPush();
	components = objc_autorelease([self.pathComponents mutableCopy]);
	fileName = components.lastObject;

	pos = [fileName rangeOfString: @"."
			      options: OFStringSearchBackwards].location;
	if (pos == OFNotFound || pos == 0) {
		objc_autoreleasePoolPop(pool);
		return objc_autoreleaseReturnValue([self copy]);
	}

	fileName = [fileName substringToIndex: pos];
	[components replaceObjectAtIndex: components.count - 1
			      withObject: fileName];

	ret = [OFString pathWithComponents: components];

	objc_retain(ret);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
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
		return objc_autoreleaseReturnValue([self copy]);
	}

	array = objc_autorelease([components mutableCopy]);

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

	objc_retain(ret);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(ret);
}

- (OFString *)stringByAppendingPathComponent: (OFString *)component
{
	if (self.length == 0)
		return component;

	if ([self hasSuffix: @"/"] || [self hasSuffix: @":"])
		return [self stringByAppendingString: component];
	else {
		OFMutableString *ret = objc_autorelease([self mutableCopy]);

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
		    objc_autorelease([self.pathComponents mutableCopy]);
		fileName = [components.lastObject
		    stringByAppendingFormat: @".%@", extension];
		[components replaceObjectAtIndex: components.count - 1
				      withObject: fileName];

		ret = objc_retain([OFString pathWithComponents: components]);
		objc_autoreleasePoolPop(pool);
		return objc_autoreleaseReturnValue(ret);
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
	components = objc_autorelease(
	    [[path componentsSeparatedByString: @"/"] mutableCopy]);
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
