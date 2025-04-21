/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFOptionsParser.h"
#import "OFApplication.h"
#import "OFArray.h"
#import "OFMapTable.h"

#import "OFInvalidArgumentException.h"

static unsigned long
stringHash(void *object)
{
	return ((OFString *)object).hash;
}

static bool
stringEqual(void *object1, void *object2)
{
	return [(OFString *)object1 isEqual: (OFString *)object2];
}

@implementation OFOptionsParser
@synthesize lastOption = _lastOption, lastLongOption = _lastLongOption;
@synthesize argument = _argument;

+ (instancetype)parserWithOptions: (const OFOptionsParserOption *)options
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithOptions: options]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithOptions: (const OFOptionsParserOption *)options
{
	self = [super init];

	@try {
		size_t count = 0;
		const OFOptionsParserOption *iter;
		OFOptionsParserOption *iter2;
		const OFMapTableFunctions keyFunctions = {
			.hash = stringHash,
			.equal = stringEqual
		};
		const OFMapTableFunctions objectFunctions = { NULL };

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

		_options = OFAllocMemory(count + 1, sizeof(*_options));
		_longOptions = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions];

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
					objc_release(iter2->longOption);

					iter2->shortOption = '\0';
					iter2->longOption = nil;

					@throw e;
				}
			}
		}
		iter2->shortOption = '\0';
		iter2->longOption = nil;

		_arguments = objc_retain([OFApplication arguments]);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_options != NULL)
		for (OFOptionsParserOption *iter = _options;
		    iter->shortOption != '\0' || iter->longOption != nil;
		    iter++)
			objc_release(iter->longOption);

	OFFreeMemory(_options);
	objc_release(_longOptions);

	objc_release(_arguments);
	objc_release(_argument);

	[super dealloc];
}

- (OFUnichar)nextOption
{
	OFOptionsParserOption *iter;
	OFString *argument;

	if (_done || _index >= _arguments.count)
		return '\0';

	objc_release(_lastLongOption);
	objc_release(_argument);
	_lastLongOption = nil;
	_argument = nil;

	argument = [_arguments objectAtIndex: _index];

	if (_subIndex == 0) {
		if (argument.length < 2 ||
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
			OFOptionsParserOption *option;

			_lastOption = '-';
			_index++;

			if ((pos = [argument rangeOfString: @"="].location) !=
			    OFNotFound)
				_argument = [[argument
				    substringFromIndex: pos + 1] copy];
			else
				pos = argument.length;

			_lastLongOption = [[argument substringWithRange:
			    OFMakeRange(2, pos - 2)] copy];

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
				    objc_autorelease([_argument copy]);

			if (option->shortOption != '\0')
				_lastOption = option->shortOption;

			return _lastOption;
		}

		_subIndex = 1;
	}

	_lastOption = [argument characterAtIndex: _subIndex++];

	if (_subIndex >= argument.length) {
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

			if (_index >= _arguments.count)
				return ':';

			argument = [_arguments objectAtIndex: _index];
			argument = [argument substringFromIndex: _subIndex];

			_argument = [argument copy];

			if (iter->isSpecifiedPtr != NULL)
				*iter->isSpecifiedPtr = true;
			if (iter->argumentPtr != NULL)
				*iter->argumentPtr =
				    objc_autorelease([_argument copy]);

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
	    OFMakeRange(_index, _arguments.count - _index)];
}
@end
