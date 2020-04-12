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
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

#ifdef OF_AMIGAOS
# include <proto/dos.h>
# include <proto/exec.h>
# include <proto/locale.h>
#endif

static OFLocale *currentLocale = nil;

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
			} @catch (OFInvalidEncodingException *e) {
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
	OFMutableArray *stack;

	if (condition.length == 0)
		return true;

	stack = [OFMutableArray array];
	for (OFString *atom in [condition
	    componentsSeparatedByString: @" "
				options: OF_STRING_SKIP_EMPTY]) {
		enum {
			TYPE_LITERAL,
			TYPE_VARIABLE,
			TYPE_EQUAL,
			TYPE_NOT_EQUAL,
			TYPE_LESS,
			TYPE_LESS_EQUAL,
			TYPE_GREATER,
			TYPE_GREATER_EQUAL,
			TYPE_ADD,
			TYPE_MODULO,
			TYPE_AND,
			TYPE_OR,
			TYPE_NOT,
			TYPE_IS_REAL
		} type;
		id var, first, second;
		size_t stackSize;

		if ([atom isEqual: @"=="]) {
			type = TYPE_EQUAL;
		} else if ([atom isEqual: @"!="]) {
			type = TYPE_NOT_EQUAL;
		} else if ([atom isEqual: @"<"]) {
			type = TYPE_LESS;
		} else if ([atom isEqual: @"<="]) {
			type = TYPE_LESS_EQUAL;
		} else if ([atom isEqual: @">"]) {
			type = TYPE_GREATER;
		} else if ([atom isEqual: @">="]) {
			type = TYPE_GREATER_EQUAL;
		} else if ([atom isEqual: @"+"]) {
			type = TYPE_ADD;
		} else if ([atom isEqual: @"%"]) {
			type = TYPE_MODULO;
		} else if ([atom isEqual: @"&&"]) {
			type = TYPE_AND;
		} else if ([atom isEqual: @"||"]) {
			type = TYPE_OR;
		} else if ([atom isEqual: @"!"]) {
			type = TYPE_NOT;
		} else if ([atom isEqual: @"."]) {
			type = TYPE_IS_REAL;
		} else {
			of_unichar_t firstCharacter =
			    [atom characterAtIndex: 0];

			if ((firstCharacter >= '0' && firstCharacter <= '9') ||
			    firstCharacter == '-')
				type = TYPE_LITERAL;
			else
				type = TYPE_VARIABLE;
		}

		switch (type) {
		case TYPE_LITERAL:
			[stack addObject:
			    [OFNumber numberWithDouble: atom.doubleValue]];
			break;
		case TYPE_VARIABLE:
			if ((var = [variables objectForKey: atom]) == nil)
				@throw [OFInvalidFormatException exception];

			if ([var isKindOfClass: [OFString class]])
				var = [OFNumber numberWithDouble:
				    [var doubleValue]];

			[stack addObject: var];
			break;
		case TYPE_EQUAL:
		case TYPE_NOT_EQUAL:
		case TYPE_LESS:
		case TYPE_LESS_EQUAL:
		case TYPE_GREATER:
		case TYPE_GREATER_EQUAL:
		case TYPE_ADD:
		case TYPE_MODULO:
		case TYPE_AND:
		case TYPE_OR:
			stackSize = stack.count;
			first = [stack objectAtIndex: stackSize - 2];
			second = [stack objectAtIndex: stackSize - 1];

			switch (type) {
			case TYPE_EQUAL:
				var = [OFNumber numberWithBool:
				    [first isEqual: second]];
				break;
			case TYPE_NOT_EQUAL:
				var = [OFNumber numberWithBool:
				    ![first isEqual: second]];
				break;
			case TYPE_LESS:
				var = [OFNumber numberWithBool: [first
				    compare: second] == OF_ORDERED_ASCENDING];
				break;
			case TYPE_LESS_EQUAL:
				var = [OFNumber numberWithBool: [first
				    compare: second] != OF_ORDERED_DESCENDING];
				break;
			case TYPE_GREATER:
				var = [OFNumber numberWithBool: [first
				    compare: second] == OF_ORDERED_DESCENDING];
				break;
			case TYPE_GREATER_EQUAL:
				var = [OFNumber numberWithBool: [first
				    compare: second] != OF_ORDERED_ASCENDING];
				break;
			case TYPE_ADD:
				var = [OFNumber numberWithDouble:
				    [first doubleValue] + [second doubleValue]];
				break;
			case TYPE_MODULO:
				var = [OFNumber numberWithIntMax:
				    [first intMaxValue] % [second intMaxValue]];
				break;
			case TYPE_AND:
				var = [OFNumber numberWithBool:
				    [first boolValue] && [second boolValue]];
				break;
			case TYPE_OR:
				var = [OFNumber numberWithBool:
				    [first boolValue] || [second boolValue]];
				break;
			default:
				OF_ENSURE(0);
			}

			[stack replaceObjectAtIndex: stackSize - 2
					 withObject: var];
			[stack removeLastObject];

			break;
		case TYPE_NOT:
		case TYPE_IS_REAL:
			stackSize = stack.count;
			first = stack.lastObject;

			switch (type) {
			case TYPE_NOT:
				var = [OFNumber numberWithBool:
				    ![first boolValue]];
				break;
			case TYPE_IS_REAL:
				var = [OFNumber numberWithBool:
				    [first doubleValue] != [first intMaxValue]];
				break;
			default:
				OF_ENSURE(0);
			}

			[stack replaceObjectAtIndex: stackSize - 1
					 withObject: var];
			break;
		}
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
			} @catch (OFInvalidEncodingException *e) {
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
				union {
					uint32_t u32;
					char c[4];
				} territory;
				size_t length;

				territory.u32 =
				    OF_BSWAP32_IF_LE(locale->loc_CountryCode);

				for (length = 0; length < 4; length++)
					if (territory.c[length] == 0)
						break;

				_territory = [[OFString alloc]
				    initWithCString: territory.c
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
			  fallback: (OFConstantString *)fallback, ...
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
			  fallback: (OFConstantString *)fallback
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
		UTF8String = fallback.UTF8String;
		UTF8StringLength = fallback.UTF8StringLength;
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
