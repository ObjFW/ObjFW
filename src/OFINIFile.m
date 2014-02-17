/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFINIFile.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFFile.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

#import "autorelease.h"
#import "macros.h"

@interface OFINIFile (OF_PRIVATE_CATEGORY)
- (void)OF_parseFile: (OFString*)path;
@end

@interface OFINICategory (OF_PRIVATE_CATEGORY)
- (instancetype)OF_init;
- (void)OF_parseLine: (OFString*)line;
- (bool)OF_writeToStream: (OFStream*)stream
		   first: (bool)first;
@end

@interface OFINICategory_Pair: OFObject
{
@public
	OFString *_key, *_value;
}
@end

@interface OFINICategory_Comment: OFObject
{
@public
	OFString *_comment;
}
@end

static bool
isWhitespaceLine(OFString *line)
{
	const char *cString = [line UTF8String];
	size_t i, length = [line UTF8StringLength];

	for (i = 0; i < length; i++) {
		switch (cString[i]) {
		case ' ':
		case '\t':
		case '\n':
		case '\r':
			continue;
		default:
			return false;
		}
	}

	return true;
}

@implementation OFINICategory
- (instancetype)OF_init
{
	self = [super init];

	@try {
		_lines = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_name release];
	[_lines release];

	[super dealloc];
}

- (void)setName: (OFString*)name
{
	OF_SETTER(_name, name, true, true)
}

- (OFString*)name
{
	OF_GETTER(_name, true)
}

- (void)OF_parseLine: (OFString*)line
{
	if (![line hasPrefix: @";"]) {
		OFINICategory_Pair *pair =
		    [[[OFINICategory_Pair alloc] init] autorelease];
		OFString *key, *value;
		size_t pos;

		if ((pos = [line rangeOfString: @"="].location) == OF_NOT_FOUND)
			@throw [OFInvalidFormatException exception];

		key = [line substringWithRange: of_range(0, pos)];
		value = [line substringWithRange:
		    of_range(pos + 1, [line length] - pos - 1)];

		if ([key hasSuffix: @" "]) {
			key = [key stringByDeletingEnclosingWhitespaces];
			value = [value stringByDeletingEnclosingWhitespaces];
		}

		pair->_key = [key copy];
		pair->_value = [value copy];

		[_lines addObject: pair];
	} else {
		OFINICategory_Comment *comment =
		    [[[OFINICategory_Comment alloc] init] autorelease];

		comment->_comment = [line copy];

		[_lines addObject: comment];
	}
}

- (OFString*)stringForKey: (OFString*)key
{
	return [self stringForKey: key
		     defaultValue: nil];
}

- (OFString*)stringForKey: (OFString*)key
	     defaultValue: (OFString*)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [_lines objectEnumerator];
	id line;

	while ((line = [enumerator nextObject]) != nil) {
		OFINICategory_Pair *pair;

		if (![line isKindOfClass: [OFINICategory_Pair class]])
			continue;

		pair = line;

		if ([pair->_key isEqual: key]) {
			OFString *value = [pair->_value copy];

			objc_autoreleasePoolPop(pool);

			return [value autorelease];
		}
	}

	objc_autoreleasePoolPop(pool);

	return defaultValue;
}

- (intmax_t)integerForKey: (OFString*)key
	     defaultValue: (intmax_t)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringForKey: key
				defaultValue: nil];
	intmax_t ret;

	if (value != nil) {
		if ([value hasPrefix: @"0x"] || [value hasPrefix: @"$"])
			ret = [value hexadecimalValue];
		else
			ret = [value decimalValue];
	} else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)boolForKey: (OFString*)key
      defaultValue: (bool)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringForKey: key
				defaultValue: nil];
	bool ret;

	if (value != nil) {
		if ([value isEqual: @"true"])
			ret = true;
		else if ([value isEqual: @"false"])
			ret = false;
		else
			@throw [OFInvalidFormatException exception];
	} else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (float)floatForKey: (OFString*)key
	defaultValue: (float)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringForKey: key
				defaultValue: nil];
	float ret;

	if (value != nil)
		ret = [value floatValue];
	else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (double)doubleForKey: (OFString*)key
	  defaultValue: (double)defaultValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *value = [self stringForKey: key
				defaultValue: nil];
	double ret;

	if (value != nil)
		ret = [value doubleValue];
	else
		ret = defaultValue;

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)setString: (OFString*)string
	   forKey: (OFString*)key
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [_lines objectEnumerator];
	OFINICategory_Pair *pair;
	id line;

	while ((line = [enumerator nextObject]) != nil) {
		if (![line isKindOfClass: [OFINICategory_Pair class]])
			continue;

		pair = line;

		if ([pair->_key isEqual: key]) {
			OFString *old = pair->_value;
			pair->_value = [string copy];
			[old release];

			objc_autoreleasePoolPop(pool);

			return;
		}
	}

	pair = [[[OFINICategory_Pair alloc] init] autorelease];
	pair->_key = [key copy];
	pair->_value = [string copy];
	[_lines addObject: pair];

	objc_autoreleasePoolPop(pool);
}

- (void)setInteger: (intmax_t)integer
	    forKey: (OFString*)key
{
	void *pool = objc_autoreleasePoolPush();

	[self setString: [OFString stringWithFormat: @"%jd", integer]
		 forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setBool: (bool)bool_
	 forKey: (OFString*)key
{
	if (bool_)
		[self setString: @"true"
			 forKey: key];
	else
		[self setString: @"false"
			 forKey: key];
}

- (void)setFloat: (float)float_
	  forKey: (OFString*)key
{
	void *pool = objc_autoreleasePoolPush();

	[self setString: [OFString stringWithFormat: @"%g", float_]
		 forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setDouble: (double)double_
	   forKey: (OFString*)key
{
	void *pool = objc_autoreleasePoolPush();

	[self setString: [OFString stringWithFormat: @"%lg", double_]
		 forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)removeValueForKey: (OFString*)key
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [_lines objectEnumerator];
	size_t i;
	id line;

	i = 0;
	while ((line = [enumerator nextObject]) != nil) {
		OFINICategory_Pair *pair;

		if (![line isKindOfClass: [OFINICategory_Pair class]]) {
			i++;
			continue;
		}

		pair = line;

		if ([pair->_key isEqual: key]) {
			[_lines removeObjectAtIndex: i];
			break;
		}

		i++;
	}

	objc_autoreleasePoolPop(pool);
}

- (bool)OF_writeToStream: (OFStream*)stream
		   first: (bool)first
{
	OFEnumerator *enumerator;
	id line;

	if ([_lines count] == 0)
		return false;

	if (first)
		[stream writeFormat: @"[%@]\n", _name];
	else
		[stream writeFormat: @"\n[%@]\n", _name];

	enumerator = [_lines objectEnumerator];
	while ((line = [enumerator nextObject]) != nil) {
		if ([line isKindOfClass: [OFINICategory_Comment class]]) {
			OFINICategory_Comment *comment = line;
			[stream writeLine: comment->_comment];
		} else if ([line isKindOfClass: [OFINICategory_Pair class]]) {
			OFINICategory_Pair *pair = line;
			[stream writeFormat: @"%@=%@\n",
					     pair->_key, pair->_value];
		} else
			@throw [OFInvalidArgumentException exception];
	}

	return true;
}
@end

@implementation OFINICategory_Pair
- (void)dealloc
{
	[_key release];
	[_value release];

	[super dealloc];
}
@end

@implementation OFINICategory_Comment
- (void)dealloc
{
	[_comment release];

	[super dealloc];
}
@end

@implementation OFINIFile
+ (instancetype)fileWithPath: (OFString*)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
{
	self = [super init];

	@try {
		_categories = [[OFMutableArray alloc] init];

		[self OF_parseFile: path];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_categories release];

	[super dealloc];
}

- (OFINICategory*)categoryForName: (OFString*)name
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [_categories objectEnumerator];
	OFINICategory *category;

	while ((category = [enumerator nextObject]) != nil) {
		if ([[category name] isEqual: name]) {
			OFINICategory *ret = [category retain];

			objc_autoreleasePoolPop(pool);

			return [ret autorelease];
		}
	}

	category = [[[OFINICategory alloc] OF_init] autorelease];
	[category setName: name];
	[_categories addObject: category];

	[category retain];

	objc_autoreleasePoolPop(pool);

	return [category autorelease];
}

- (void)OF_parseFile: (OFString*)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"r"];
	OFINICategory *category = nil;
	OFString *line;

	while ((line = [file readLine]) != nil) {
		if (isWhitespaceLine(line))
			continue;

		if ([line hasPrefix: @"["]) {
			OFString *categoryName;

			if (![line hasSuffix: @"]"])
				@throw [OFInvalidFormatException exception];

			categoryName = [line substringWithRange:
			    of_range(1, [line length] - 2)];

			category = [[[OFINICategory alloc]
			    OF_init] autorelease];
			[category setName: categoryName];
			[_categories addObject: category];
		} else {
			if (category == nil)
				@throw [OFInvalidFormatException exception];

			[category OF_parseLine: line];
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (void)writeToFile: (OFString*)path
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file = [OFFile fileWithPath: path
				       mode: @"w"];
	OFEnumerator *enumerator = [_categories objectEnumerator];
	OFINICategory *category;
	bool first = true;

	while ((category = [enumerator nextObject]) != nil)
		if ([category OF_writeToStream: file
					 first: first])
			first = false;

	objc_autoreleasePoolPop(pool);
}
@end
