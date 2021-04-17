/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
 * The global variables @ref of_stdin, @ref of_stdout and @ref of_stderr are
 * instances of this class and need no initialization.
 */
#ifdef OF_STDIO_STREAM_WIN32_CONSOLE_H
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFStdIOStream: OFStream
#if !defined(OF_WINDOWS) && !defined(OF_AMIGAOS)
    <OFReadyForReadingObserving, OFReadyForWritingObserving>
#endif
{
#ifndef OF_AMIGAOS
	int _fd;
#else
	BPTR _handle;
	bool _closable;
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
extern OFStdIOStream *_Nullable of_stdin;

/**
 * @brief The standard output as an OFStream.
 */
extern OFStdIOStream *_Nullable of_stdout;

/**
 * @brief The standard error as an OFStream.
 */
extern OFStdIOStream *_Nullable of_stderr;

/**
 * @brief Log the specified printf-style format to @ref of_stderr.
 *
 * This prefixes the output with the date, timestamp, process name and PID and
 * allows `%@` as a printf-style formatted to print objects.
 */
extern void of_log(OFConstantString *format, ...);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
