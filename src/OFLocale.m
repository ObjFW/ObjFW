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

#include <locale.h>

#import "OFLocale.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFIRI.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFString+Private.h"

#import "OFOnce.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/dos.h>
# include <proto/exec.h>
# include <proto/locale.h>
# undef Class
#endif

OF_DIRECT_MEMBERS
@interface OFLocale ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
@end

static OFOnceControl initLocaleControl = OFOnceControlInitValue;
static OFLocale *currentLocale = nil;
static OFDictionary *operatorPrecedences = nil;

static void
initLocale(void)
{
	currentLocale = [[OFLocale alloc] of_init];
}

#ifndef OF_AMIGAOS
static void
parseLocale(char *locale, OFStringEncoding *encoding,
    OFString **languageCode, OFString **countryCode)
{
	locale = _OFStrDup(locale);

	@try {
		OFStringEncoding enc = OFStringEncodingASCII;
		char *tmp;

		/* We don't care for extras behind the @ */
		if ((tmp = strrchr(locale, '@')) != NULL)
			*tmp = '\0';

		/* Encoding */
		if ((tmp = strrchr(locale, '.')) != NULL) {
			*tmp++ = '\0';

			@try {
				if (encoding != NULL)
					*encoding = OFStringEncodingParseName(
					    [OFString stringWithCString: tmp
							       encoding: enc]);
			} @catch (OFInvalidArgumentException *e) {
			}
		}

		/* Country code */
		if ((tmp = strrchr(locale, '_')) != NULL) {
			*tmp++ = '\0';

			if (countryCode != NULL)
				*countryCode = [OFString
				    stringWithCString: tmp
					     encoding: enc];
		}

		if (languageCode != NULL)
			*languageCode = [OFString stringWithCString: locale
							   encoding: enc];
	} @finally {
		OFFreeMemory(locale);
	}
}
#endif

static bool
evaluateCondition(OFString *condition_, OFDictionary *variables)
{
	OFMutableString *condition = objc_autorelease([condition_ mutableCopy]);
	OFMutableArray *tokens, *operators, *stack;

	/* Empty condition is the fallback that's always true */
	if (condition.length == 0)
		return true;

	/*
	 * Dirty hack to allow not needing spaces after "!" or "(" and spaces
	 * before ")".
	 * TODO: Replace with a proper tokenizer.
	 */
	[condition replaceOccurrencesOfString: @"!" withString: @"! "];
	[condition replaceOccurrencesOfString: @"(" withString: @"( "];
	[condition replaceOccurrencesOfString: @")" withString: @" )"];

	/* Substitute variables and convert to RPN first */
	tokens = [OFMutableArray array];
	operators = [OFMutableArray array];
	for (OFString *token in [condition
	    componentsSeparatedByString: @" "
				options: OFStringSkipEmptyComponents]) {
		unsigned precedence;
		OFUnichar c;

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
				    compare: second] == OFOrderedAscending];
			else if ([token isEqual: @"<="])
				var = [OFNumber numberWithBool: [first
				    compare: second] != OFOrderedDescending];
			else if ([token isEqual: @">"])
				var = [OFNumber numberWithBool: [first
				    compare: second] == OFOrderedDescending];
			else if ([token isEqual: @">="])
				var = [OFNumber numberWithBool: [first
				    compare: second] != OFOrderedAscending];
			else if ([token isEqual: @"+"])
				var = [OFNumber numberWithDouble:
				    [first doubleValue] + [second doubleValue]];
			else if ([token isEqual: @"%"])
				var = [OFNumber numberWithLongLong:
				    [first longLongValue] %
				    [second longLongValue]];
			else if ([token isEqual: @"&&"])
				var = [OFNumber numberWithBool:
				    [first boolValue] && [second boolValue]];
			else if ([token isEqual: @"||"])
				var = [OFNumber numberWithBool:
				    [first boolValue] || [second boolValue]];
			else
				OFEnsure(0);

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
				    ([first doubleValue] !=
				    [first longLongValue])];
			else
				OFEnsure(0);

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
@synthesize languageCode = _languageCode, countryCode = _countryCode;
@synthesize encoding = _encoding, decimalSeparator = _decimalSeparator;

+ (void)initialize
{
	void *pool;
	OFNumber *one, *two, *three, *four;

	if (self != [OFLocale class])
		return;

	pool = objc_autoreleasePoolPush();

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

	objc_autoreleasePoolPop(pool);
}

+ (OFLocale *)currentLocale
{
	OFOnce(&initLocaleControl, initLocale);

	return currentLocale;
}

+ (OFString *)languageCode
{
	OFOnce(&initLocaleControl, initLocale);

	return currentLocale.languageCode;
}

+ (OFString *)countryCode
{
	OFOnce(&initLocaleControl, initLocale);

	return currentLocale.countryCode;
}

+ (OFStringEncoding)encoding
{
	OFOnce(&initLocaleControl, initLocale);

	return currentLocale.encoding;
}

+ (OFString *)decimalSeparator
{
	OFOnce(&initLocaleControl, initLocale);

	return currentLocale.decimalSeparator;
}

+ (void)addLocalizationDirectoryIRI: (OFIRI *)IRI
{
	[currentLocale addLocalizationDirectoryIRI: IRI];
}

- (instancetype)init
{
	/*
	 * In the past, applications not using OFApplication were required to
	 * create an instance of OFLocale manually. This is no longer needed
	 * and +[currentLocale] creates the singleton. However, in order to not
	 * break old applications, this method needs to just return the
	 * singleton now.
	 */
	objc_release(self);

	return [OFLocale currentLocale];
}

- (instancetype)of_init
{
	self = [super init];

	@try {
#ifndef OF_AMIGAOS
		char *locale, *messagesLocale = NULL;

# ifdef OF_MSDOS
		_encoding = OFStringEncodingCodepage437;
# else
		_encoding = OFStringEncodingUTF8;
# endif
		_decimalSeparator = @".";
		_localizedStrings = [[OFMutableArray alloc] init];

		if ((locale = setlocale(LC_ALL, "")) != NULL)
			_decimalSeparator = [[OFString alloc]
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
			    &_languageCode, &_countryCode);

			objc_retain(_languageCode);
			objc_retain(_countryCode);

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
			OFStringEncoding ASCII = OFStringEncodingASCII;

			@try {
				_encoding = OFStringEncodingParseName(
				    [OFString stringWithCString: buffer
						       encoding: ASCII]);
			} @catch (OFInvalidArgumentException *e) {
				_encoding = OFStringEncodingISO8859_1;
			}
		} else
			_encoding = OFStringEncodingISO8859_1;

		/*
		 * Get it via localeconv() instead of from the Locale struct,
		 * to make sure we and printf etc. have the same expectations.
		 */
		_decimalSeparator = [[OFString alloc]
		    initWithCString: localeconv()->decimal_point
			   encoding: _encoding];

		_localizedStrings = [[OFMutableArray alloc] init];

		if (GetVar("Language", buffer, sizeof(buffer), 0) > 0)
			_languageCode = [[OFString alloc]
			    initWithCString: buffer
				   encoding: _encoding];

		if ((locale = OpenLocale(NULL)) != NULL) {
			@try {
				uint32_t countryCode;
				size_t length;

				countryCode =
				    OFToBigEndian32(locale->loc_CountryCode);

				for (length = 0; length < 4; length++)
					if (((char *)&countryCode)[length] == 0)
						break;

				_countryCode = [[OFString alloc]
				    initWithCString: (char *)&countryCode
					   encoding: _encoding
					     length: length];
			} @finally {
				CloseLocale(locale);
			}
		}

		objc_autoreleasePoolPop(pool);
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

OF_SINGLETON_METHODS

- (void)addLocalizationDirectoryIRI: (OFIRI *)IRI
{
	void *pool;
	OFIRI *mapIRI, *localizationIRI;
	OFString *languageCode, *countryCode, *localizationFile;
	OFDictionary *map;

	if (_languageCode == nil)
		return;

	pool = objc_autoreleasePoolPush();

	mapIRI = [IRI IRIByAppendingPathComponent: @"localizations.json"];
	@try {
		map = [[OFString stringWithContentsOfIRI: mapIRI]
		     objectByParsingJSON];
	} @catch (OFOpenItemFailedException *e) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	languageCode = _languageCode.lowercaseString;
	countryCode = _countryCode.lowercaseString;

	if (countryCode == nil)
		countryCode = @"";

	localizationFile = [[map objectForKey: languageCode]
	    objectForKey: countryCode];
	if (localizationFile == nil)
		localizationFile = [[map objectForKey: languageCode]
		    objectForKey: @""];

	if (localizationFile == nil) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	localizationIRI = [IRI IRIByAppendingPathComponent:
	    [localizationFile stringByAppendingString: @".json"]];

	[_localizedStrings addObject: [[OFString stringWithContentsOfIRI:
	    localizationIRI] objectByParsingJSON]];

	objc_autoreleasePoolPop(pool);
}

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
		[variables setObject: va_arg(arguments, id) forKey: name];

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
