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

#include "config.h"

#import "OFOptionsParser.h"
#import "OFApplication.h"
#import "OFArray.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFOptionsParser
+ (instancetype)parserWithOptions: (OFString*)options
{
	return [[[self alloc] initWithOptions: options] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithOptions: (OFString*)options
{
	self = [super init];

	@try {
		_options = [self allocMemoryWithSize: sizeof(of_unichar_t)
					       count: [options length] + 1];
		[options getCharacters: _options
			       inRange: of_range(0, [options length])];
		_options[[options length]] = 0;

		_arguments = [[OFApplication arguments] retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_arguments release];
	[_argument release];

	[super dealloc];
}

- (of_unichar_t)nextOption
{
	of_unichar_t *options;
	OFString *argument;

	if (_done || _index >= [_arguments count])
		return '\0';

	argument = [_arguments objectAtIndex: _index];

	if (_subIndex == 0) {
		if ([argument length] < 2 ||
		    [argument characterAtIndex: 0] != '-') {
			_done = true;
			return '\0';
		}

		if ([argument isEqual: @"--"]) {
			_done = true;
			_index++;
			return '\0';
		}

		_subIndex = 1;
	}

	_lastOption = [argument characterAtIndex: _subIndex++];

	if (_subIndex >= [argument length]) {
		_index++;
		_subIndex = 0;
	}

	for (options = _options; *options != 0; options++) {
		if (_lastOption == *options) {
			if (options[1] != ':') {
				[_argument release];
				_argument = nil;
				return _lastOption;
			}

			if (_index >= [_arguments count])
				return ':';

			argument = [_arguments objectAtIndex: _index];
			argument = [argument substringWithRange:
			    of_range(_subIndex, [argument length] - _subIndex)];

			[_argument release];
			_argument = [argument copy];

			_index++;
			_subIndex = 0;

			return _lastOption;
		}
	}

	return '?';
}

- (of_unichar_t)lastOption
{
	return _lastOption;
}

- (OFString*)argument
{
	return [[_argument copy] autorelease];
}

- (OFArray*)remainingArguments
{
	return [_arguments objectsInRange:
	    of_range(_index, [_arguments count] - _index)];
}
@end
