/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include <locale.h>

#import "OFLocale.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
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
	const char *UTF8String = NULL;
	size_t last, UTF8StringLength;
	int state = 0;

	for (OFDictionary *strings in _localizedStrings) {
		id string = [strings objectForKey: ID];

		if (string == nil)
			continue;

		if ([string isKindOfClass: [OFArray class]])
			string = [string componentsJoinedByString: @""];

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
				va_list argsCopy;
				OFConstantString *name;

				OFString *var = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				/*
				 * We loop, as most of the time, we only have
				 * one or maybe two variables, meaning looping
				 * is faster than constructing a dictionary.
				 */
				va_copy(argsCopy, arguments);
				while ((name = va_arg(argsCopy,
				    OFConstantString *)) != nil) {
					id value = va_arg(argsCopy, id);

					if (value == nil)
						@throw
						    [OFInvalidArgumentException
						    exception];

					if ([name isEqual: var]) {
						[ret appendString:
						    [value description]];
						break;
					}
				}

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
