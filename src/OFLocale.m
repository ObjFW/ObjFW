/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <locale.h>

#import "OFLocale.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

#ifdef OF_AMIGAOS
# include <proto/dos.h>
# include <proto/exec.h>
# include <proto/locale.h>
#endif

static OFLocale *currentLocale = nil;
static OFDictionary *operatorPrecedences = nil;

#ifndef OF_AMIGAOS
static void
parseLocale(char *locale, of_string_encoding_t *encoding,
    OFString **language, OFString **territory)
{
	if ((locale = of_strdup(locale)) == NULL)
		return;

	@try {
		const of_string_encoding_t enc = OF_STRING_ENCODING_ASCII;
		char *tmp;

		/* We don't care for extras behind the @ */
		if ((tmp = strrchr(locale, '@')) != NULL)
			*tmp = '\0';

		/* Encoding */
		if ((tmp = strrchr(locale, '.')) != NULL) {
			*tmp++ = '\0';

			@try {
				if (encoding != NULL)
					*encoding = of_string_parse_encoding(
					    [OFString stringWithCString: tmp
							       encoding: enc]);
			} @catch (OFInvalidArgumentException *e) {
			}
		}

		/* Territory */
		if ((tmp = strrchr(locale, '_')) != NULL) {
			*tmp++ = '\0';

			if (territory != NULL)
				*territory = [OFString stringWithCString: tmp
								encoding: enc];
		}

		if (language != NULL)
			*language = [OFString stringWithCString: locale
						       encoding: enc];
	} @finally {
		free(locale);
	}
}
#endif

static bool
evaluateCondition(OFString *condition, OFDictionary *variables)
{
	OFMutableArray *tokens, *operators, *stack;

	/* Empty condition is the fallback that's always true */
	if (condition.length == 0)
		return true;

	/*
	 * Dirty hack to allow not needing spaces after "!" or "(" and spaces
	 * before ")".
	 * TODO: Replace with a proper tokenizer.
	 */
	condition = [condition stringByReplacingOccurrencesOfString: @"!"
							 withString: @"! "];
	condition = [condition stringByReplacingOccurrencesOfString: @"("
							 withString: @"( "];
	condition = [condition stringByReplacingOccurrencesOfString: @")"
							 withString: @" )"];

	/* Substitute variables and convert to RPN first */
	tokens = [OFMutableArray array];
	operators = [OFMutableArray array];
	for (OFString *token in [condition
	    componentsSeparatedByString: @" "
				options: OF_STRING_SKIP_EMPTY]) {
		unsigned precedence;
		of_unichar_t c;

		if ([token isEqual: @"("]) {
			[operators addObject: @"("];
			continue;
		}

		if ([token isEqual: @")"]) {
			for (;;) {
				OFString *operator = operators.lastObject;
				if (operator == nil)
					@throw [OFInvalidFormatException
					    exception];

				if ([operator isEqual: @"("]) {
					[operators removeLastObject];
					break;
				}

				[tokens addObject: operator];
				[operators removeLastObject];
			}
			continue;
		}

		precedence = [[operatorPrecedences objectForKey: token]
		    unsignedIntValue];
		if (precedence > 0) {
			for (;;) {
				OFNumber *operator = operators.lastObject;
				unsigned otherPrecedence;

				if (operator == nil || [operator isEqual: @"("])
					break;

				otherPrecedence = [[operatorPrecedences
				    objectForKey: operator] unsignedIntValue];
				if (otherPrecedence >= precedence)
					break;

				[tokens addObject: operator];
				[operators removeLastObject];
			}

			[operators addObject: token];
			continue;
		}

		c = [token characterAtIndex: 0];
		if ((c < '0' || c > '9') && c != '-')
			if ((token = [variables objectForKey: token]) == nil)
				@throw [OFInvalidFormatException exception];

		[tokens addObject:
		    [OFNumber numberWithDouble: token.doubleValue]];
	}
	for (size_t i = operators.count; i > 0; i--) {
		OFString *operator = [operators objectAtIndex: i - 1];

		if ([operator isEqual: @"("])
			@throw [OFInvalidFormatException exception];

		[tokens addObject: operator];
	}

	/* Evaluate RPN */
	stack = [OFMutableArray array];
	for (id token in tokens) {
		unsigned precedence = [[operatorPrecedences
		    objectForKey: token] unsignedIntValue];
		id var, first, second;
		size_t stackSize;

		/* Only unary operators have precedence 1 */
		if (precedence > 1) {
			stackSize = stack.count;
			first = [stack objectAtIndex: stackSize - 2];
			second = [stack objectAtIndex: stackSize - 1];

			if ([token isEqual: @"=="])
				var = [OFNumber numberWithBool:
				    [first isEqual: second]];
			else if ([token isEqual: @"!="])
				var = [OFNumber numberWithBool:
				    ![first isEqual: second]];
			else if ([token isEqual: @"<"])
				var = [OFNumber numberWithBool: [first
				    compare: second] == OF_ORDERED_ASCENDING];
			else if ([token isEqual: @"<="])
				var = [OFNumber numberWithBool: [first
				    compare: second] != OF_ORDERED_DESCENDING];
			else if ([token isEqual: @">"])
				var = [OFNumber numberWithBool: [first
				    compare: second] == OF_ORDERED_DESCENDING];
			else if ([token isEqual: @">="])
				var = [OFNumber numberWithBool: [first
				    compare: second] != OF_ORDERED_ASCENDING];
			else if ([token isEqual: @"+"])
				var = [OFNumber numberWithDouble:
				    [first doubleValue] + [second doubleValue]];
			else if ([token isEqual: @"%"])
				var = [OFNumber numberWithIntMax:
				    [first intMaxValue] % [second intMaxValue]];
			else if ([token isEqual: @"&&"])
				var = [OFNumber numberWithBool:
				    [first boolValue] && [second boolValue]];
			else if ([token isEqual: @"||"])
				var = [OFNumber numberWithBool:
				    [first boolValue] || [second boolValue]];
			else
				OF_ENSURE(0);

			[stack replaceObjectAtIndex: stackSize - 2
					 withObject: var];
			[stack removeLastObject];
		} else if (precedence == 1) {
			stackSize = stack.count;
			first = stack.lastObject;

			if ([token isEqual: @"!"])
				var = [OFNumber numberWithBool:
				    ![first boolValue]];
			else if ([token isEqual: @"is_real"])
				var = [OFNumber numberWithBool:
				    [first doubleValue] != [first intMaxValue]];
			else
				OF_ENSURE(0);

			[stack replaceObjectAtIndex: stackSize - 1
					 withObject: var];
		} else
			[stack addObject: token];
	}

	if (stack.count != 1)
		@throw [OFInvalidFormatException exception];

	return [stack.firstObject boolValue];
}

static OFString *
evaluateConditionals(OFArray *conditions, OFDictionary *variables)
{
	for (OFDictionary *dictionary in conditions) {
		OFString *condition, *value;
		bool found = false;

		for (OFString *key in dictionary) {
			if (found)
				@throw [OFInvalidFormatException exception];

			condition = key;
			value = [dictionary objectForKey: key];

			if (![condition isKindOfClass: [OFString class]] ||
			    ![value isKindOfClass: [OFString class]])
				@throw [OFInvalidFormatException exception];

			found = true;
		}
		if (!found)
			@throw [OFInvalidFormatException exception];

		if (evaluateCondition(condition, variables))
			return value;
	}

	/* Need to have a fallback as the last one. */
	@throw [OFInvalidFormatException exception];
}

static OFString *
evaluateArray(OFArray *array, OFDictionary *variables)
{
	OFMutableString *string = [OFMutableString string];

	for (id object in array) {
		if ([object isKindOfClass: [OFString class]])
			[string appendString: object];
		else if ([object isKindOfClass: [OFArray class]])
			[string appendString:
			    evaluateConditionals(object, variables)];
		else
			@throw [OFInvalidFormatException exception];
	}

	[string makeImmutable];

	return string;
}

@implementation OFLocale
@synthesize language = _language, territory = _territory, encoding = _encoding;
@synthesize decimalPoint = _decimalPoint;

+ (void)initialize
{
	OFNumber *one, *two, *three, *four;

	if (self != [OFLocale class])
		return;

	/* 1 is also used to denote a unary operator. */
	one = [OFNumber numberWithUnsignedInt: 1];
	two = [OFNumber numberWithUnsignedInt: 2];
	three = [OFNumber numberWithUnsignedInt: 3];
	four = [OFNumber numberWithUnsignedInt: 4];

	operatorPrecedences = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"==", two,
	    @"!=", two,
	    @"<", two,
	    @"<=", two,
	    @">", two,
	    @">=", two,
	    @"+", two,
	    @"%", two,
	    @"&&", three,
	    @"||", four,
	    @"!", one,
	    @"is_real", one,
	    nil];
}

+ (OFLocale *)currentLocale
{
	return currentLocale;
}

+ (OFString *)language
{
	return currentLocale.language;
}

+ (OFString *)territory
{
	return currentLocale.territory;
}

+ (of_string_encoding_t)encoding
{
	return currentLocale.encoding;
}

+ (OFString *)decimalPoint
{
	return currentLocale.decimalPoint;
}

#ifdef OF_HAVE_FILES
+ (void)addLanguageDirectory: (OFString *)path
{
	[currentLocale addLanguageDirectory: path];
}
#endif

- (instancetype)init
{
	self = [super init];

	@try {
#ifndef OF_AMIGAOS
		char *locale, *messagesLocale = NULL;

		if (currentLocale != nil)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_encoding = OF_STRING_ENCODING_UTF_8;
		_decimalPoint = @".";
		_localizedStrings = [[OFMutableArray alloc] init];

		if ((locale = setlocale(LC_ALL, "")) != NULL)
			_decimalPoint = [[OFString alloc]
			    initWithCString: localeconv()->decimal_point
				   encoding: _encoding];

# ifdef LC_MESSAGES
		messagesLocale = setlocale(LC_MESSAGES, "");
# endif
		if (messagesLocale == NULL)
			messagesLocale = locale;

		if (messagesLocale != NULL) {
			void *pool = objc_autoreleasePoolPush();

			parseLocale(messagesLocale, &_encoding,
			    &_language, &_territory);

			[_language retain];
			[_territory retain];

			objc_autoreleasePoolPop(pool);
		}
#else
		void *pool = objc_autoreleasePoolPush();
		char buffer[32];
		struct Locale *locale;

		/*
		 * Returns an empty string on MorphOS + libnix, but still
		 * applies it so that printf etc. work as expected.
		 */
		setlocale(LC_ALL, "");

# if defined(OF_MORPHOS)
		if (GetVar("CODEPAGE", buffer, sizeof(buffer), 0) > 0) {
# elif defined(OF_AMIGAOS4)
		if (GetVar("Charset", buffer, sizeof(buffer), 0) > 0) {
# else
		if (0) {
# endif
			of_string_encoding_t ASCII = OF_STRING_ENCODING_ASCII;

			@try {
				_encoding = of_string_parse_encoding(
				    [OFString stringWithCString: buffer
						       encoding: ASCII]);
			} @catch (OFInvalidArgumentException *e) {
				_encoding = OF_STRING_ENCODING_ISO_8859_1;
			}
		} else
			_encoding = OF_STRING_ENCODING_ISO_8859_1;

		/*
		 * Get it via localeconv() instead of from the Locale struct,
		 * to make sure we and printf etc. have the same expectations.
		 */
		_decimalPoint = [[OFString alloc]
		    initWithCString: localeconv()->decimal_point
			   encoding: _encoding];

		_localizedStrings = [[OFMutableArray alloc] init];

		if (GetVar("Language", buffer, sizeof(buffer), 0) > 0)
			_language = [[OFString alloc]
			    initWithCString: buffer
				   encoding: _encoding];

		if ((locale = OpenLocale(NULL)) != NULL) {
			@try {
				uint32_t territory;
				size_t length;

				territory =
				    OF_BSWAP32_IF_LE(locale->loc_CountryCode);

				for (length = 0; length < 4; length++)
					if (((char *)territory)[length] == 0)
						break;

				_territory = [[OFString alloc]
				    initWithCString: territory
					   encoding: _encoding
					     length: length];
			} @finally {
				CloseLocale(locale);
			}
		}

		objc_autoreleasePoolPop(pool);
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	currentLocale = self;

	return self;
}

- (void)dealloc
{
	[_language release];
	[_territory release];
	[_decimalPoint release];
	[_localizedStrings release];

	[super dealloc];
}

#ifdef OF_HAVE_FILES
- (void)addLanguageDirectory: (OFString *)path
{
	void *pool;
	OFString *mapPath, *language, *territory, *languageFile;
	OFDictionary *map;

	if (_language == nil)
		return;

	pool = objc_autoreleasePoolPush();

	mapPath = [path stringByAppendingPathComponent: @"languages.json"];
	@try {
		map = [[OFString stringWithContentsOfFile: mapPath] JSONValue];
	} @catch (OFOpenItemFailedException *e) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	language = _language.lowercaseString;
	territory = _territory.lowercaseString;

	if (territory == nil)
		territory = @"";

	languageFile = [[map objectForKey: language] objectForKey: territory];
	if (languageFile == nil)
		languageFile = [[map objectForKey: language] objectForKey: @""];

	if (languageFile == nil) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	languageFile = [path stringByAppendingPathComponent:
	    [languageFile stringByAppendingString: @".json"]];

	[_localizedStrings addObject:
	    [[OFString stringWithContentsOfFile: languageFile] JSONValue]];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFString *)localizedStringForID: (OFConstantString *)ID
			  fallback: (id)fallback, ...
{
	OFString *ret;
	va_list args;

	va_start(args, fallback);
	ret = [self localizedStringForID: ID
				fallback: fallback
			       arguments: args];
	va_end(args);

	return ret;
}

- (OFString *)localizedStringForID: (OFConstantString *)ID
			  fallback: (id)fallback
			 arguments: (va_list)arguments
{
	OFMutableString *ret = [OFMutableString string];
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary *variables;
	OFConstantString *name;
	const char *UTF8String = NULL;
	size_t last, UTF8StringLength;
	int state = 0;

	variables = [OFMutableDictionary dictionary];
	while ((name = va_arg(arguments, OFConstantString *)) != nil)
		[variables setObject: va_arg(arguments, id)
			      forKey: name];

	for (OFDictionary *strings in _localizedStrings) {
		id string = [strings objectForKey: ID];

		if (string == nil)
			continue;

		if ([string isKindOfClass: [OFArray class]])
			string = evaluateArray(string, variables);

		UTF8String = [string UTF8String];
		UTF8StringLength = [string UTF8StringLength];
		break;
	}

	if (UTF8String == NULL) {
		if ([fallback isKindOfClass: [OFArray class]])
			fallback = evaluateArray(fallback, variables);

		UTF8String = [fallback UTF8String];
		UTF8StringLength = [fallback UTF8StringLength];
	}

	state = 0;
	last = 0;
	for (size_t i = 0; i < UTF8StringLength; i++) {
		switch (state) {
		case 0:
			if (UTF8String[i] == '%') {
				[ret appendUTF8String: UTF8String + last
					       length: i - last];

				last = i + 1;
				state = 1;
			}
			break;
		case 1:
			if (UTF8String[i] == '[') {
				last = i + 1;
				state = 2;
			} else {
				[ret appendString: @"%"];
				state = 0;
			}
			break;
		case 2:
			if (UTF8String[i] == ']') {
				OFString *var = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];
				OFString *value = [variables objectForKey: var];

				if (value != nil)
					[ret appendString: value.description];

				last = i + 1;
				state = 0;
			}
			break;
		}
	}
	switch (state) {
	case 1:
		[ret appendString: @"%"];
		/* Explicit fall-through */
	case 0:
		[ret appendUTF8String: UTF8String + last
			       length: UTF8StringLength - last];
		break;
	}

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return ret;
}
@end
