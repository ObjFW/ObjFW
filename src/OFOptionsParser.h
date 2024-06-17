/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFString.h"

@class OFMapTable;

OF_ASSUME_NONNULL_BEGIN

/**
 * @struct OFOptionsParserOption OFOptionsParser.h ObjFW/ObjFW.h
 *
 * @brief An option which can be parsed by an @ref OFOptionsParser.
 */
typedef struct {
	/** The short version (e.g. `-v`) of the option or `\0` for none. */
	OFUnichar shortOption;

	/**
	 * The long version (e.g. `--verbose`) of the option or `nil` for none.
	 */
	OFString *__unsafe_unretained _Nullable longOption;

	/**
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

	/**
	 * An optional pointer to a bool that is set to whether the option has
	 * been specified.
	 */
	bool *_Nullable isSpecifiedPtr;

	/**
	 * An optional pointer to an `OFString *` that is set to the
	 * argument specified for the option or `nil` for no argument.
	 */
	OFString *__autoreleasing _Nullable *_Nullable argumentPtr;
} OFOptionsParserOption;

/**
 * @class OFOptionsParser OFOptionsParser.h ObjFW/ObjFW.h
 *
 * @brief A class for parsing the program options specified on the command line.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFOptionsParser: OFObject
{
	OFOptionsParserOption *_options;
	OFMapTable *_longOptions;
	OFArray OF_GENERIC(OFString *) *_arguments;
	size_t _index, _subIndex;
	OFUnichar _lastOption;
	OFString *_Nullable _lastLongOption, *_Nullable _argument;
	bool _done;
}

/**
 * @brief The last parsed option.
 *
 * If @ref nextOption returned `?` or `:`, this returns the option which was
 * unknown or for which the argument was missing.@n
 * If this returns `-`, the last option is only available as a long option (see
 * lastLongOption).
 */
@property (readonly, nonatomic) OFUnichar lastOption;

/**
 * @brief The long option for the last parsed option, or `nil` if the last
 *	  parsed option was not passed as a long option by the user.
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

/**
 * @brief The argument for the last parsed option, or `nil` if the last parsed
 *	  option takes no argument.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *argument;

/**
 * @brief The arguments following the last option.
 */
@property (readonly, nonatomic)
    OFArray OF_GENERIC(OFString *) *remainingArguments;

/**
 * @brief Creates a new OFOptionsParser which accepts the specified options.
 *
 * @param options An array of @ref OFOptionsParserOption specifying all
 *		  accepted options, terminated with an option whose short
 *		  option is `\0` and long option is `nil`.
 *
 * @return A new, autoreleased OFOptionsParser
 */
+ (instancetype)parserWithOptions: (const OFOptionsParserOption *)options;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFOptionsParser so that it accepts
 *	  the specified options.
 *
 * @param options An array of @ref OFOptionsParserOption specifying all
 *		  accepted options, terminated with an option whose short
 *		  option is `\0` and long option is `nil`.
 *
 * @return An initialized OFOptionsParser
 */
- (instancetype)initWithOptions: (const OFOptionsParserOption *)options
    OF_DESIGNATED_INITIALIZER;

/**
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
- (OFUnichar)nextOption;
@end

OF_ASSUME_NONNULL_END
