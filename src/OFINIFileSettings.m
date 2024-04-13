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

#include "config.h"

#import "OFINIFileSettings.h"
#import "OFArray.h"
#import "OFINIFile.h"
#import "OFIRI.h"
#import "OFString.h"
#import "OFSystemInfo.h"

@implementation OFINIFileSettings
- (instancetype)initWithApplicationName: (OFString *)applicationName
{
	self = [super initWithApplicationName: applicationName];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName;

		fileName = [applicationName stringByAppendingString: @".ini"];
		_fileIRI = [[[OFSystemInfo userConfigIRI]
		    IRIByAppendingPathComponent: fileName] copy];
		_INIFile = [[OFINIFile alloc] initWithIRI: _fileIRI];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_fileIRI release];
	[_INIFile release];

	[super dealloc];
}

- (void)of_getCategory: (OFString **)category
		andKey: (OFString **)key
	       forPath: (OFString *)path OF_DIRECT
{
	size_t pos = [path rangeOfString: @"."
				 options: OFStringSearchBackwards].location;

	if (pos == OFNotFound) {
		*category = @"";
		*key = path;
		return;
	}

	*category = [path substringToIndex: pos];
	*key = [path substringFromIndex: pos + 1];
}

- (void)setString: (OFString *)string forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setStringValue: string
						      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setLongLong: (long long)longLong forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setLongLongValue: longLong
							forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setBool: (bool)bool_ forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setBoolValue: bool_ forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setFloat: (float)float_ forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setFloatValue: float_
						     forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setDouble: (double)double_ forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setDoubleValue: double_
						      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setStringArray: (OFArray OF_GENERIC(OFString *) *)array
	       forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setArrayValue: array
						     forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)stringForPath: (OFString *)path
	       defaultValue: (OFString *)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key, *ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category]
	    stringValueForKey: key
		 defaultValue: defaultValue];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (long long)longLongForPath: (OFString *)path
		defaultValue: (long long)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	long long ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category]
	    longLongValueForKey: key
		   defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)boolForPath: (OFString *)path defaultValue: (bool)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	bool ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category]
	    boolValueForKey: key
	       defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (float)floatForPath: (OFString *)path defaultValue: (float)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	float ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category]
	    floatValueForKey: key
		defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (double)doubleForPath: (OFString *)path defaultValue: (double)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	double ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category]
	    doubleValueForKey: key
		 defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFArray OF_GENERIC(OFString *) *)stringArrayForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	OFArray *ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category] arrayValueForKey: key];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (void)removeValueForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] removeValueForKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)save
{
	[_INIFile writeToIRI: _fileIRI];
}
@end
