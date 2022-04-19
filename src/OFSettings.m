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

#import "OFSettings.h"
#import "OFINIFileSettings.h"
#import "OFString.h"

@implementation OFSettings
@synthesize applicationName = _applicationName;

+ (instancetype)alloc
{
	if (self == [OFSettings class])
		return [OFINIFileSettings alloc];

	return [super alloc];
}

+ (instancetype)settingsWithApplicationName: (OFString *)applicationName
{
	return [[[self alloc]
	    initWithApplicationName: applicationName] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithApplicationName: (OFString *)applicationName
{
	self = [super init];

	@try {
		_applicationName = [applicationName copy];
	} @catch (id e) {
		@throw e;
		[self release];
	}

	return self;
}

- (void)dealloc
{
	[_applicationName release];

	[super dealloc];
}

- (void)setString: (OFString *)string forPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setLongLong: (long long)longLong forPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setBool: (bool)bool_ forPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setFloat: (float)float_ forPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setDouble: (double)double_ forPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setStringArray: (OFArray OF_GENERIC(OFString *) *)array
	       forPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)stringForPath: (OFString *)path
{
	return [self stringForPath: path defaultValue: nil];
}

- (OFString *)stringForPath: (OFString *)path
	       defaultValue: (OFString *)defaultValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (long long)longLongForPath: (OFString *)path
		defaultValue: (long long)defaultValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)boolForPath: (OFString *)path defaultValue: (bool)defaultValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (float)floatForPath: (OFString *)path defaultValue: (float)defaultValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (double)doubleForPath: (OFString *)path defaultValue: (double)defaultValue
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFArray OF_GENERIC(OFString *) *)stringArrayForPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeValueForPath: (OFString *)path
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)save
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
