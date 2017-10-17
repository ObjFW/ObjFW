/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

#define OF_LOCALIZED(ID, ...)				\
	[[OFLocalization sharedLocalization]		\
	    localizedStringForID: ID			\
			fallback: __VA_ARGS__, nil]

@class OFMutableArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/*!
 * @class OFLocalization OFLocalization.h ObjFW/OFLocalization.h
 *
 * @brief A class for querying the locale and retrieving localized strings.
 */
@interface OFLocalization: OFObject
{
	OFString *_Nullable _language, *_Nullable _territory;
	of_string_encoding_t _encoding;
	OFString *_decimalPoint;
	OFMutableArray OF_GENERIC(OFDictionary OF_GENERIC(OFString *, id) *)
	    *_localizedStrings;
}

/*!
 * The language of the locale for messages.
 *
 * If the language is unknown, it is `nil`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *language;

/*!
 * The territory of the locale for messages.
 *
 * If the territory is unknown, it is `nil`.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *territory;

/*!
 * The native 8-bit string encoding of the locale for messages.
 *
 * This is useful to encode strings correctly for passing them to operating
 * system calls.
 *
 * If the native 8-bit encoding is unknown, UTF-8 is assumed.
 */
@property (readonly, nonatomic) of_string_encoding_t encoding;

/*!
 * The decimal point of the system's locale.
 */
@property (readonly, nonatomic) OFString *decimalPoint;

/*!
 * @brief Returns the shared OFLocalization instance.
 *
 * @warning If you don't use @ref OFApplication, this might be `nil`! In this
 *	    case, you need to manually allocate an instance and call
 *	    @ref init once.
 *
 * @return The shared OFLocalization instance
 */
+ (instancetype)sharedLocalization;

/*!
 * @brief Returns the language of the locale.
 *
 * If the language is unknown, `nil` is returned.
 *
 * @return The language of the locale.
 */
+ (nullable OFString *)language;

/*!
 * @brief Returns the territory of the locale.
 *
 * If the territory is unknown, `nil` is returned.
 *
 * @return The territory of the locale.
 */
+ (nullable OFString *)territory;

/*!
 * @brief Returns the native 8-bit string encoding for the locale.
 *
 * This is useful to encode strings correctly for passing them to operating
 * system calls.
 *
 * If the native 8-bit encoding is unknown, UTF-8 is assumed.
 *
 * @return The native 8-bit string encoding for the locale
 */
+ (of_string_encoding_t)encoding;

/*!
 * @brief Returns the decimal point of the system's locale.
 *
 * @return The decimal point of the system's locale
 */
+ (OFString *)decimalPoint;

#ifdef OF_HAVE_FILES
/*!
 * @brief Adds a directory to scan for language files.
 *
 * @param path The path to the directory to scan for language files
 */
+ (void)addLanguageDirectory: (OFString *)path;
#endif

/*!
 * @brief Initializes the OFLocalization singleton with the specified locale.
 *
 * @warning This sets the locale via `setlocale()`!
 *
 * @warning You should never call this yourself, except if you do not use
 *	    @ref OFApplication. In this case, you need to allocate exactly one
 *	    instance of OFLocalization, which will be come the singleton, and
 *	    call this method.
 */
- (instancetype)init;

#ifdef OF_HAVE_FILES
/*!
 * @brief Adds a directory to scan for language files.
 *
 * @param path The path to the directory to scan for language files
 */
- (void)addLanguageDirectory: (OFString *)path;
#endif

/*!
 * @brief Returns the localized string for the specified ID, using the fallback
 *	  string if it cannot be looked up or is missing.
 *
 * @note This takes a variadic argument, terminated by `nil`, that consists of
 *	 pairs of variable names and variable values, which will be replaced
 *	 inside the localized string. For example, you can pass
 *	 `@"name", @"foo", nil`, causing `%[name]` to be replaced with `foo` in
 *	 the localized string.
 *
 * @note Generally, you want to use @ref OF_LOCALIZED instead, which also takes
 *	 care of the `nil` sentinel automatically.
 *
 * @param ID The ID for the localized string
 * @param fallback The fallback to use in case the localized string cannot be
 *		   looked up or is missing
 * @return The localized string
 */
- (OFString *)localizedStringForID: (OFConstantString *)ID
			  fallback: (OFConstantString *)fallback, ...
				    OF_SENTINEL;

/*!
 * @brief Returns the localized string for the specified ID, using the fallback
 *	  string if it cannot be looked up or is missing.
 *
 * @note This takes a variadic argument, terminated by `nil` and passed as
 *	 va_list, that consists of pairs of variable names and variable values,
 *	 which will be replaced inside the localized string. For example, you
 *	 can pass `@"name", @"foo", nil`, causing `%[name]` to be replaced with
 *	 `foo` in the localized string.
 *
 * @note Generally, you want to use @ref OF_LOCALIZED instead, which also takes
 *	 care of the `nil` sentinel automatically.
 *
 * @param ID The ID for the localized string
 * @param fallback The fallback to use in case the localized string cannot be
 *		   looked up or is missing
 * @param arguments A va_list of arguments, consisting of pairs of variable
 *		    names and values to replace in the localized string,
 *		    terminated with `nil`
 * @return The localized string
 */
- (OFString *)localizedStringForID: (OFConstantString *)ID
			  fallback: (OFConstantString *)fallback
			 arguments: (va_list)arguments;
@end

OF_ASSUME_NONNULL_END
