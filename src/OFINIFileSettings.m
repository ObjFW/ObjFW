/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
	       forPath: (OFString *)path OF_DIRECT
{
	size_t pos = [path rangeOfString: @"."
				 options: OF_STRING_SEARCH_BACKWARDS].location;

	if (pos == OF_NOT_FOUND) {
		*category = @"";
		*key = path;
		return;
	}

	*category = [path substringToIndex: pos];
	*key = [path substringFromIndex: pos + 1];
}

- (void)setStringValue: (OFString *)string
	       forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setStringValue: string
						      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setLongLongValue: (long long)longLongValue
		 forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setLongLongValue: longLongValue
							forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setBoolValue: (bool)boolValue
	     forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setBoolValue: boolValue
						    forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setFloatValue: (float)floatValue
	      forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setFloatValue: floatValue
						     forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setDoubleValue: (double)doubleValue
	       forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setDoubleValue: doubleValue
						      forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setStringValues: (OFArray OF_GENERIC(OFString *) *)stringValues
		forPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	[[_INIFile categoryForName: category] setStringValues: stringValues
						       forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)stringValueForPath: (OFString *)path
		    defaultValue: (OFString *)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key, *ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category]
	    stringValueForKey: key
		 defaultValue: defaultValue];

	[ret retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (long long)longLongValueForPath: (OFString *)path
		     defaultValue: (long long)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	long long ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category]
	    longLongValueForKey: key
		   defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)boolValueForPath: (OFString *)path
	    defaultValue: (bool)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	bool ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category]
	    boolValueForKey: key
	       defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (float)floatValueForPath: (OFString *)path
	      defaultValue: (float)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	float ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category]
	    floatValueForKey: key
		defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (double)doubleValueForPath: (OFString *)path
		defaultValue: (double)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	double ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category]
	    doubleValueForKey: key
		 defaultValue: defaultValue];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFArray OF_GENERIC(OFString *) *)stringValuesForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();
	OFString *category, *key;
	OFArray *ret;

	[self of_getCategory: &category
		      andKey: &key
		     forPath: path];

	ret = [[_INIFile categoryForName: category] stringValuesForKey: key];

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
