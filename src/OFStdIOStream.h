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

#import "OFStream.h"
#import "OFKernelEventObserver.h"

#ifdef OF_AMIGAOS
# include <dos/dos.h>
#endif

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFColor;

/**
 * @class OFStdIOStream OFStdIOStream.h ObjFW/OFStdIOStream.h
 *
 * @brief A class for providing standard input, output and error as OFStream.
 *
 * The global variables @ref OFStdIn, @ref OFStdOut and @ref OFStdErr are
 * instances of this class and need no initialization.
 */
#ifdef OF_STDIO_STREAM_WIN32_CONSOLE_H
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFStdIOStream: OFStream
#if !defined(OF_WINDOWS) && !defined(OF_AMIGAOS) && !defined(OF_WII_U)
    <OFReadyForReadingObserving, OFReadyForWritingObserving>
#endif
{
#if defined(OF_AMIGAOS)
	BPTR _handle;
	bool _closable;
#elif !defined(OF_WII_U)
	int _fd;
#endif
	bool _atEndOfStream;
}

/**
 * @brief Whether there is an underlying terminal.
 */
@property (readonly, nonatomic) bool hasTerminal;

/**
 * @brief The number of columns, or -1 if there is no underlying terminal or
 *	  the number of columns could not be queried.
 */
@property (readonly, nonatomic) int columns;

/**
 * @brief The number of rows, or -1 if there is no underlying terminal or the
 *	  number of rows could not be queried.
 */
@property (readonly, nonatomic) int rows;

#if defined(OF_WII) || defined(OF_NINTENDO_DS) || defined(OF_NINTENDO_3DS) || \
    defined(DOXYGEN)
/**
 * @brief Sets up a console for @ref OFStdOut / @ref OFStdErr output on systems
 *	  that don't have a console by default.
 *
 * @note This method is only available on Wii, Nintendo DS and Nintendo 3DS.
 */
+ (void)setUpConsole;
#endif

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Sets the foreground color on the underlying terminal. Does nothing if
 *	  there is no underlying terminal or colors are unsupported.
 *
 * @param color The foreground color to set
 */
- (void)setForegroundColor: (OFColor *)color;

/**
 * @brief Sets the background color on the underlying terminal. Does nothing if
 *	  there is no underlying terminal or colors are unsupported.
 *
 * @param color The background color to set
 */
- (void)setBackgroundColor: (OFColor *)color;

/**
 * @brief Resets all attributes (color, bold, etc.). Does nothing if there is
 *	  no underlying terminal.
 */
- (void)reset;

/**
 * @brief Clears the entire underlying terminal. Does nothing if there is no
 *	  underlying terminal.
 */
- (void)clear;

/**
 * @brief Erases the entire current line on the underlying terminal. Does
 *	  nothing if there is no underlying terminal.
 */
- (void)eraseLine;

/**
 * @brief Moves the cursor to the specified column in the current row. Does
 *	  nothing if there is no underlying terminal.
 *
 * @param column The column in the current row to move the cursor to
 */
- (void)setCursorColumn: (unsigned int)column;

/**
 * @brief Moves the cursor to the specified absolute position. Does nothing if
 *	  there is no underlying terminal.
 *
 * @param position The position to move the cursor to
 */
- (void)setCursorPosition: (OFPoint)position;

/**
 * @brief Moves the cursor to the specified relative position. Does nothing if
 *	  there is no underlying terminal.
 *
 * @param position The position to move the cursor to
 */
- (void)setRelativeCursorPosition: (OFPoint)position;
@end

#ifdef __cplusplus
extern "C" {
#endif
/** @file */

/**
 * @brief The standard input as an OFStream.
 */
extern OFStdIOStream *_Nullable OFStdIn;

/**
 * @brief The standard output as an OFStream.
 */
extern OFStdIOStream *_Nullable OFStdOut;

/**
 * @brief The standard error as an OFStream.
 */
extern OFStdIOStream *_Nullable OFStdErr;

/**
 * @brief Logs the specified printf-style format to @ref OFStdErr.
 *
 * This prefixes the output with the date, timestamp, process name and PID.
 *
 * @param format The format for the line to log. See @ref OFStream#writeFormat:.
 */
extern void OFLog(OFConstantString *format, ...);

/**
 * @brief Logs the specified printf-style format to @ref OFStdErr.
 *
 * This prefixes the output with the date, timestamp, process name and PID.
 *
 * @param format The format for the line to log. See @ref OFStream#writeFormat:.
 * @param arguments The arguments for the format
 */
extern void OFLogV(OFConstantString *format, va_list arguments);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
