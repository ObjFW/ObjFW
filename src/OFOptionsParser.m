/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFOptionsParser.h"
#import "OFApplication.h"
#import "OFArray.h"
#import "OFMapTable.h"

#import "OFInvalidArgumentException.h"

static uint32_t
stringHash(void *object)
{
	return [(OFString *)object hash];
}

static bool
stringEqual(void *object1, void *object2)
{
	return [(OFString *)object1 isEqual: (OFString *)object2];
}

@implementation OFOptionsParser
@synthesize lastOption = _lastOption, lastLongOption = _lastLongOption;
@synthesize argument = _argument;

+ (instancetype)parserWithOptions: (const of_options_parser_option_t *)options
{
	return [[[self alloc] initWithOptions: options] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithOptions: (const of_options_parser_option_t *)options
{
	self = [super init];

	@try {
		size_t count = 0;
		const of_options_parser_option_t *iter;
		of_options_parser_option_t *iter2;
		const of_map_table_functions_t keyFunctions = {
			.hash = stringHash,
			.equal = stringEqual
		};
		const of_map_table_functions_t objectFunctions = { NULL };

		/* Count, sanity check, initialize pointers */
		for (iter = options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++) {
			if (iter->hasArgument < -1 || iter->hasArgument > 1)
				@throw [OFInvalidArgumentException exception];

			if (iter->shortOption != '\0' &&
			    iter->hasArgument == -1)
				@throw [OFInvalidArgumentException exception];

			if (iter->hasArgument == 0 && iter->argumentPtr != NULL)
				@throw [OFInvalidArgumentException exception];

			if (iter->isSpecifiedPtr)
				*iter->isSpecifiedPtr = false;
			if (iter->argumentPtr)
				*iter->argumentPtr = nil;

			count++;
		}

		_longOptions = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions];
		_options = [self
		    allocMemoryWithSize: sizeof(*_options)
				  count: count + 1];

		for (iter = options, iter2 = _options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++, iter2++) {
			iter2->shortOption = iter->shortOption;
			iter2->longOption = nil;
			iter2->hasArgument = iter->hasArgument;
			iter2->isSpecifiedPtr = iter->isSpecifiedPtr;
			iter2->argumentPtr = iter->argumentPtr;

			if (iter->longOption != nil) {
				@try {
					iter2->longOption =
					    [iter->longOption copy];

					if ([_longOptions objectForKey:
					    iter2->longOption] != NULL)
						@throw
						    [OFInvalidArgumentException
						    exception];

					[_longOptions
					    setObject: iter2
					       forKey: iter2->longOption];
				} @catch (id e) {
					/*
					 * Make sure we are in a consistent
					 * state where dealloc works.
					 */
					[iter2->longOption release];

					iter2->shortOption = '\0';
					iter2->longOption = nil;

					@throw e;
				}
			}
		}
		iter2->shortOption = '\0';
		iter2->longOption = nil;

		_arguments = [[OFApplication arguments] retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	of_options_parser_option_t *iter;

	[_longOptions release];

	if (_options != NULL)
		for (iter = _options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++)
			[iter->longOption release];

	[_arguments release];
	[_argument release];

	[super dealloc];
}

- (of_unichar_t)nextOption
{
	of_options_parser_option_t *iter;
	OFString *argument;

	if (_done || _index >= [_arguments count])
		return '\0';

	[_lastLongOption release];
	[_argument release];
	_lastLongOption = nil;
	_argument = nil;

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

		if ([argument hasPrefix: @"--"]) {
			void *pool = objc_autoreleasePoolPush();
			size_t pos;
			of_options_parser_option_t *option;

			_lastOption = '-';
			_index++;

			if ((pos = [argument rangeOfString: @"="].location) !=
			    OF_NOT_FOUND) {
				of_range_t range = of_range(pos + 1,
				    [argument length] - pos - 1);
				_argument = [[argument
				    substringWithRange: range] copy];
			} else
				pos = [argument length];

			_lastLongOption = [[argument substringWithRange:
			    of_range(2, pos - 2)] copy];

			objc_autoreleasePoolPop(pool);

			option = [_longOptions objectForKey: _lastLongOption];
			if (option == NULL)
				return '?';

			if (option->hasArgument == 1 && _argument == nil)
				return ':';
			if (option->hasArgument == 0 && _argument != nil)
				return '=';

			if (option->isSpecifiedPtr != NULL)
				*option->isSpecifiedPtr = true;
			if (option->argumentPtr != NULL)
				*option->argumentPtr =
				    [[_argument copy] autorelease];

			if (option->shortOption != '\0')
				_lastOption = option->shortOption;

			return _lastOption;
		}

		_subIndex = 1;
	}

	_lastOption = [argument characterAtIndex: _subIndex++];

	if (_subIndex >= [argument length]) {
		_index++;
		_subIndex = 0;
	}

	for (iter = _options;
	    iter->shortOption != '\0' || iter->longOption != nil; iter++) {
		if (iter->shortOption == _lastOption) {
			if (iter->hasArgument == 0) {
				if (iter->isSpecifiedPtr != NULL)
					*iter->isSpecifiedPtr = true;

				return _lastOption;
			}

			if (_index >= [_arguments count])
				return ':';

			argument = [_arguments objectAtIndex: _index];
			argument = [argument substringWithRange:
			    of_range(_subIndex, [argument length] - _subIndex)];

			_argument = [argument copy];

			if (iter->isSpecifiedPtr != NULL)
				*iter->isSpecifiedPtr = true;
			if (iter->argumentPtr != NULL)
				*iter->argumentPtr =
				    [[_argument copy] autorelease];

			_index++;
			_subIndex = 0;

			return _lastOption;
		}
	}

	return '?';
}

- (OFArray *)remainingArguments
{
	return [_arguments objectsInRange:
	    of_range(_index, [_arguments count] - _index)];
}
@end
