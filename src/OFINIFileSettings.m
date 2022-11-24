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
	[[_INIFile categoryForName: category] setString: string forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setLongLong: (long long)longLong forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setLongLong: longLong
						   forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setBool: (bool)bool_ forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setBool: bool_ forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setFloat: (float)float_ forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setFloat: float_ forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setDouble: (double)double_ forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setDouble: double_ forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setStringArray: (OFArray OF_GENERIC(OFString *) *)array
	       forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category andKey: &key forPath: path];
	[[_INIFile categoryForName: category] setStringArray: array
						      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)stringForPath: (OFString *)path
	       defaultValue: (OFString *)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key, *ret;

	[self of_getCategory: &category andKey: &key forPath: path];
	ret = [[_INIFile categoryForName: category] stringForKey: key
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
	    longLongForKey: key
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
	ret = [[_INIFile categoryForName: category] boolForKey: key
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
	ret = [[_INIFile categoryForName: category] floatForKey: key
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
	ret = [[_INIFile categoryForName: category] doubleForKey: key
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
	ret = [[_INIFile categoryForName: category] stringArrayForKey: key];

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
