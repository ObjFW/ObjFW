/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

/*
 * This file is also used for MS-DOS and MiNT! Don't forget to #ifdef
 * Windows-specific parts!
 */

#include "config.h"

#import "OFString+PathAdditions.h"
#import "OFArray.h"
#import "OFFileIRIHandler.h"
#import "OFIRI.h"

#import "OFInvalidFormatException.h"
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

#ifdef OF_WINDOWS
	if ([self hasPrefix: @"\\\\"]) {
		isUNC = true;
		[ret addObject: @"\\\\"];

		cString += 2;
		cStringLength -= 2;
	}
#endif

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
				    OFMakeRange(i - 1, 2)];

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
	if (self.length == 0)
		return component;

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

- (OFString *)stringByAppendingPathExtension: (OFString *)extension
{
	if ([self hasSuffix: @"\\"] || [self hasSuffix: @"/"]) {
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
	return ([self hasSuffix: @"\\"] || [self hasSuffix: @"/"] ||
	    [OFFileIRIHandler of_directoryExistsAtPath: self]);
}

- (OFString *)of_pathToIRIPathWithPercentEncodedHost:
    (OFString **)percentEncodedHost
{
	OFString *path = self;

	if ([path hasPrefix: @"\\\\"]) {
		OFArray *components = path.pathComponents;

		if (components.count < 2)
			@throw [OFInvalidFormatException exception];

		*percentEncodedHost = [[components objectAtIndex: 1]
		     stringByAddingPercentEncodingWithAllowedCharacters:
		     [OFCharacterSet IRIHostAllowedCharacterSet]];
		path = [OFString pathWithComponents: [components
		    objectsInRange: OFMakeRange(2, components.count - 2)]];
	}

	path = [path stringByReplacingOccurrencesOfString: @"\\"
					       withString: @"/"];
	path = [@"/" stringByAppendingString: path];

	return path;
}

- (OFString *)of_IRIPathToPathWithPercentEncodedHost:
    (OFString *)percentEncodedHost
{
	OFString *path = self;

	if (path.length > 1 && [path hasSuffix: @"/"] &&
	    ![path hasSuffix: @":/"])
		path = [path substringToIndex: path.length - 1];

	path = [path substringFromIndex: 1];
	path = [path stringByReplacingOccurrencesOfString: @"/"
					       withString: @"\\"];

	if (percentEncodedHost != nil) {
		OFString *host = [percentEncodedHost
		    stringByRemovingPercentEncoding];

		if (path.length == 0)
			path = [OFString stringWithFormat: @"\\\\%@", host];
		else
			path = [OFString stringWithFormat: @"\\\\%@\\%@",
							   host, path];
	}

	return path;
}

- (OFString *)of_pathComponentToIRIPathComponent
{
	return [self stringByReplacingOccurrencesOfString: @"\\"
					       withString: @"/"];
}
@end
