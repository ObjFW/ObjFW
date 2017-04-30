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

@class OFMapTable;

OF_ASSUME_NONNULL_BEGIN

/*!
 * @struct of_options_parser_option_t OFOptionsParser.h ObjFW/OFOptionsParser.h
 *
 * @brief An option which can be parsed by an @ref OFOptionsParser.
 */
typedef struct of_options_parser_option_t {
	/*! The short version (e.g. `-v`) of the option or `\0` for none. */
	of_unichar_t shortOption;

	/*!
	 * The long version (e.g. `--verbose`) of the option or `nil` for none.
	 */
	OFString *__unsafe_unretained _Nullable longOption;

	/*!
	 * Whether the option takes an argument.
	 *
	 * 0 means it takes no argument.@n
	 * 1 means it takes a required argument.@n
	 * -1 means it takes an optional argument.@n
	 *
	 * All other values are invalid and will throw an
	 * @ref OFInvalidArgumentException.
	 */
	signed char hasArgument;

	/*!
	 * An optional pointer to a bool that is set to whether the option has
	 * been specified.
	 */
	bool *_Nullable isSpecifiedPtr;

	/*!
	 * An optional pointer to an @ref OFString* that is set to the argument
	 * specified for the option or `nil` for no argument.
	 */
	OFString *__autoreleasing _Nullable *_Nullable argumentPtr;
} of_options_parser_option_t;

/*!
 * @class OFOptionsParser OFOptionsParser.h ObjFW/OFOptionsParser.h
 *
 * @brief A class for parsing the program options specified on the command line.
 */
@interface OFOptionsParser: OFObject
{
	of_options_parser_option_t *_options;
	OFMapTable *_longOptions;
	OFArray OF_GENERIC(OFString*) *_arguments;
	size_t _index, _subIndex;
	of_unichar_t _lastOption;
	OFString *_lastLongOption, *_argument;
	bool _done;
}

/*!
 * The last parsed option.
 *
 * If @ref nextOption returned `?` or `:`, this returns the option which was
 * unknown or for which the argument was missing.@n
 * If this returns `-`, the last option is only available as a long option (see
 * lastLongOption).
 */
@property (readonly) of_unichar_t lastOption;

/*!
 * The long option for the last parsed option, or `nil` if the last parsed
 * option was not passed as a long option by the user.
 *
 * In case @ref nextOption returned `?`, this contains the unknown long
 * option.@n
 * In case it returned `:`, this contains the long option which is missing an
 * argument.@n
 * In case it returned `=`, this contains the long option for which an
 * argument was specified even though the option takes no argument.
 *
 * @warning Unlike @ref lastOption, which returns the short option even if the
 *	    user specified a long option, this only returns the long option if
 *	    it was actually specified as a long option by the user.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *lastLongOption;

/*!
 * The argument for the last parsed option, or `nil` if the last parsed option
 * takes no argument.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *argument;

/*!
 * @brief Creates a new OFOptionsParser which accepts the specified options.
 *
 * @param options An array of @ref of_options_parser_option_t specifying all
 *		  accepted options, terminated with an option whose short
 *		  option is `\0` and long option is `nil`.
 *
 * @return A new, autoreleased OFOptionsParser
 */
+ (instancetype)parserWithOptions: (const of_options_parser_option_t*)options;

/*!
 * @brief Initializes an already allocated OFOptionsParser so that it accepts
 *	  the specified options.
 *
 * @param options An array of @ref of_options_parser_option_t specifying all
 *		  accepted options, terminated with an option whose short
 *		  option is `\0` and long option is `nil`.
 *
 * @return An initialized OFOptionsParser
 */
- initWithOptions: (const of_options_parser_option_t*)options;

/*!
 * @brief Returns the next option.
 *
 * If the option is only available as a long option, `-` is returned.
 * Otherwise, the short option is returned, even if it was specified as a long
 * option.@n
 * If an unknown option is specified, `?` is returned.@n
 * If the argument for the option is missing, `:` is returned.@n
 * If there is an argument for the option even though it takes none, `=` is
 * returned.@n
 * If all options have been parsed, `\0` is returned.
 *
 * @note You need to call @ref nextOption repeatedly until it returns `\0` to
 *	 make sure all options have been parsed, even if you only rely on the
 *	 optional pointers specified and don't do any parsing yourself.
 *
 * @return The next option
 */
- (of_unichar_t)nextOption;

/*!
 * @brief Returns the arguments following the last option.
 *
 * @return The arguments following the last option
 */
- (OFArray OF_GENERIC(OFString*)*)remainingArguments;
@end

OF_ASSUME_NONNULL_END
