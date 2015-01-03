/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#include "config.h"

#import "OFINICategory.h"
#import "OFINICategory+Private.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFStream.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

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

static OFString*
escapeString(OFString *string)
{
	OFMutableString *mutableString;

	/* FIXME: Optimize */
	if (![string hasPrefix: @" "] && ![string hasPrefix: @"\t"] &&
	    ![string hasPrefix: @"\f"] && ![string hasSuffix: @" "] &&
	    ![string hasSuffix: @"\t"] && ![string hasSuffix: @"\f"] &&
	    ![string containsString: @"\""])
		return string;

	mutableString = [[string mutableCopy] autorelease];

	[mutableString replaceOccurrencesOfString: @"\\"
				       withString: @"\\\\"];
	[mutableString replaceOccurrencesOfString: @"\f"
				       withString: @"\\f"];
	[mutableString replaceOccurrencesOfString: @"\r"
				       withString: @"\\r"];
	[mutableString replaceOccurrencesOfString: @"\n"
				       withString: @"\\n"];
	[mutableString replaceOccurrencesOfString: @"\""
				       withString: @"\\\""];

	[mutableString prependString: @"\""];
	[mutableString appendString: @"\""];

	[mutableString makeImmutable];

	return mutableString;
}

static OFString*
unescapeString(OFString *string)
{
	OFMutableString *mutableString;

	if (![string hasPrefix: @"\""] || ![string hasSuffix: @"\""])
		return string;

	string = [string substringWithRange: of_range(1, [string length] - 2)];
	mutableString = [[string mutableCopy] autorelease];

	[mutableString replaceOccurrencesOfString: @"\\f"
				       withString: @"\f"];
	[mutableString replaceOccurrencesOfString: @"\\r"
				       withString: @"\r"];
	[mutableString replaceOccurrencesOfString: @"\\n"
				       withString: @"\n"];
	[mutableString replaceOccurrencesOfString: @"\\\""
				       withString: @"\""];
	[mutableString replaceOccurrencesOfString: @"\\\\"
				       withString: @"\\"];

	[mutableString makeImmutable];

	return mutableString;
}

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

		key = [key stringByDeletingEnclosingWhitespaces];
		value = [value stringByDeletingEnclosingWhitespaces];

		key = unescapeString(key);
		value = unescapeString(value);

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

- (OFArray*)arrayForKey: (OFString*)key
{
	OFMutableArray *ret = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [_lines objectEnumerator];
	id line;

	while ((line = [enumerator nextObject]) != nil) {
		OFINICategory_Pair *pair;

		if (![line isKindOfClass: [OFINICategory_Pair class]])
			continue;

		pair = line;

		if ([pair->_key isEqual: key])
			[ret addObject: [[pair->_value copy] autorelease]];
	}

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

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
	[self setString: (bool_ ? @"true" : @"false")
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

	[self setString: [OFString stringWithFormat: @"%g", double_]
		 forKey: key];

	objc_autoreleasePoolPop(pool);
}

- (void)setArray: (OFArray*)array
	  forKey: (OFString*)key
{
	void *pool;
	OFEnumerator *enumerator;
	OFMutableArray *pairs;
	id object;
	id const *lines;
	size_t i, count;
	bool replaced;

	if ([array count] == 0) {
		[self removeValueForKey: key];
		return;
	}

	pool = objc_autoreleasePoolPush();

	enumerator = [array objectEnumerator];
	pairs = [OFMutableArray arrayWithCapacity: [array count]];

	while ((object = [enumerator nextObject]) != nil) {
		OFINICategory_Pair *pair;

		if (![object isKindOfClass: [OFString class]])
			@throw [OFInvalidArgumentException exception];

		pair = [[[OFINICategory_Pair alloc] init] autorelease];
		pair->_key = [key copy];
		pair->_value = [object copy];

		[pairs addObject: pair];
	}

	lines = [_lines objects];
	count = [_lines count];
	replaced = false;

	for (i = 0; i < count; i++) {
		OFINICategory_Pair *pair;

		if (![lines[i] isKindOfClass: [OFINICategory_Pair class]])
			continue;

		pair = lines[i];

		if ([pair->_key isEqual: key]) {
			[_lines removeObjectAtIndex: i];

			if (!replaced) {
				[_lines insertObjectsFromArray: pairs
						       atIndex: i];

				replaced = true;
				/* Continue after inserted pairs */
				i += [array count] - 1;
			} else
				i--;	/* Continue at same position */

			lines = [_lines objects];
			count = [_lines count];

			continue;
		}
	}

	if (!replaced)
		[_lines addObjectsFromArray: pairs];

	objc_autoreleasePoolPop(pool);
}

- (void)removeValueForKey: (OFString*)key
{
	void *pool = objc_autoreleasePoolPush();
	id const *lines = [_lines objects];
	size_t i, count = [_lines count];

	for (i = 0; i < count; i++) {
		OFINICategory_Pair *pair;

		if (![lines[i] isKindOfClass: [OFINICategory_Pair class]])
			continue;

		pair = lines[i];

		if ([pair->_key isEqual: key]) {
			[_lines removeObjectAtIndex: i];

			lines = [_lines objects];
			count = [_lines count];

			i--;	/* Continue at same position */
			continue;
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (bool)OF_writeToStream: (OFStream*)stream
		encoding: (of_string_encoding_t)encoding
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
			OFString *key = escapeString(pair->_key);
			OFString *value = escapeString(pair->_value);
			OFString *line = [OFString
			    stringWithFormat: @"%@=%@\n", key, value];

			[stream writeString: line
				   encoding: encoding];
		} else
			@throw [OFInvalidArgumentException exception];
	}

	return true;
}
@end
