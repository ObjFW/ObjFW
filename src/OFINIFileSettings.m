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

#import "OFINIFileSettings.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFINIFile.h"
#import "OFSystemInfo.h"

@implementation OFINIFileSettings
- (instancetype)initWithApplicationName: (OFString *)applicationName
{
	self = [super initWithApplicationName: applicationName];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName;

		fileName = [applicationName stringByAppendingString: @".ini"];
		_filePath = [[[OFSystemInfo userConfigPath]
		    stringByAppendingPathComponent: fileName] copy];
		_INIFile = [[OFINIFile alloc] initWithPath: _filePath];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_filePath release];
	[_INIFile release];

	[super dealloc];
}

- (void)of_getCategory: (OFString **)category
		andKey: (OFString **)key
	       forPath: (OFString *)path
{
	size_t pos = [path rangeOfString: @"."
				 options: OF_STRING_SEARCH_BACKWARDS].location;

	if (pos == OF_NOT_FOUND) {
		*category = @"";
		*key = path;
		return;
	}

	*category = [path substringWithRange: of_range(0, pos)];
	*key = [path substringWithRange:
	    of_range(pos + 1, path.length - pos - 1)];
}

- (void)setString: (OFString *)string
	  forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setString: string
						 forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setInteger: (intmax_t)integer
	   forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setInteger: integer
						  forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setBool: (bool)bool_
	forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setBool: bool_
					       forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setFloat: (float)float_
	 forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setFloat: float_
						forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setDouble: (double)double_
	  forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setDouble: double_
						 forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setArray: (OFArray *)array
	 forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setArray: array
						forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)stringForPath: (OFString *)path
	       defaultValue: (OFString *)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key, *ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category] stringForKey: key
						    defaultValue: defaultValue];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (intmax_t)integerForPath: (OFString *)path
	      defaultValue: (intmax_t)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	intmax_t ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category]
	    integerForKey: key
	     defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)boolForPath: (OFString *)path
       defaultValue: (bool)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	bool ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category] boolForKey: key
						  defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (float)floatForPath: (OFString *)path
	 defaultValue: (float)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	float ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category] floatForKey: key
						   defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (double)doubleForPath: (OFString *)path
	   defaultValue: (double)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	double ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category] doubleForKey: key
						    defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFArray *)arrayForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	OFArray *ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category] arrayForKey: key];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (void)removeValueForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] removeValueForKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)save
{
	[_INIFile writeToFile: _filePath];
}
@end
