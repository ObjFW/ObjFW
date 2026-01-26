/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>
#include <math.h>

#include "unistd_wrapper.h"

#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif
#ifdef HAVE_SYS_TTYCOM_H
# include <sys/ttycom.h>
#endif

#import "OFStdIOStream.h"
#import "OFStdIOStream+Private.h"
#import "OFApplication.h"
#import "OFColor.h"
#import "OFDate.h"
#import "OFDictionary.h"
#ifdef OF_WINDOWS
# import "platform/Windows/OFWin32ConsoleStdIOStream.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef OF_IOS
# undef HAVE_ISATTY
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# include <proto/dos.h>
# undef Class
# undef HAVE_ISATTY
#endif

#ifdef OF_MSDOS
# include <conio.h>
#endif

#ifdef OF_WII
# define asm __asm__
# define id ogc_id
# include <gccore.h>
# undef id
# undef asm
#endif

#ifdef OF_WII_U
# define BOOL WUT_BOOL
# include <coreinit/debug.h>
# undef BOOL
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
#endif

#ifdef OF_NINTENDO_3DS
/* Newer versions of libctru started using id as a parameter name. */
# define id id_3ds
# include <3ds.h>
# undef id
#endif

/* References for static linking */
#ifdef OF_WINDOWS
void
_reference_to_OFWin32ConsoleStdIOStream(void)
{
	[OFWin32ConsoleStdIOStream class];
}
#endif

OFStdIOStream *OFStdIn = nil;
OFStdIOStream *OFStdOut = nil;
OFStdIOStream *OFStdErr = nil;

#ifdef OF_AMIGAOS
OF_DESTRUCTOR()
{
	[OFStdIn dealloc];
	[OFStdOut dealloc];
	[OFStdErr dealloc];
}
#endif

void
OFLog(OFConstantString *format, ...)
{
	va_list arguments;

	va_start(arguments, format);
	OFLogV(format, arguments);
	va_end(arguments);
}

void
OFLogV(OFConstantString *format, va_list arguments)
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *date;
	OFString *dateString, *me, *msg;

	date = [OFDate date];
	dateString = [date localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
#ifdef OF_HAVE_FILES
	me = [OFApplication programName].lastPathComponent;
#else
	me = [OFApplication programName];
#endif

	if (me == nil)
		me = @"?";

	msg = objc_autorelease([[OFString alloc] initWithFormat: format
						      arguments: arguments]);

	[OFStdErr writeFormat: @"[%@.%03d %@(%d)] %@\n", dateString,
			       date.microsecond / 1000, me, getpid(), msg];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_MSDOS
int
colorToMSDOS(OFColor *color, int default_)
{
	if (color == nil)
		return default_;
	if (color == [OFColor black])
		return BLACK;
	if (color == [OFColor navy])
		return BLUE;
	if (color == [OFColor green])
		return GREEN;
	if (color == [OFColor teal])
		return CYAN;
	if (color == [OFColor maroon])
		return RED;
	if (color == [OFColor purple])
		return MAGENTA;
	if (color == [OFColor olive])
		return BROWN;
	if (color == [OFColor silver])
		return LIGHTGRAY;
	if (color == [OFColor gray])
		return DARKGRAY;
	if (color == [OFColor blue])
		return LIGHTBLUE;
	if (color == [OFColor lime])
		return LIGHTGREEN;
	if (color == [OFColor aqua])
		return LIGHTCYAN;
	if (color == [OFColor red])
		return LIGHTRED;
	if (color == [OFColor fuchsia])
		return LIGHTMAGENTA;
	if (color == [OFColor yellow])
		return YELLOW;
	if (color == [OFColor white])
		return WHITE;

	return -1;
}
#else
static int
colorToANSI(OFColor *color)
{
	if (color == nil)
		return 39;
	if (color == [OFColor black])
		return 30;
	if (color == [OFColor maroon])
		return 31;
	if (color == [OFColor green])
		return 32;
	if (color == [OFColor olive])
		return 33;
	if (color == [OFColor navy])
		return 34;
	if (color == [OFColor purple])
		return 35;
	if (color == [OFColor teal])
		return 36;
	if (color == [OFColor silver])
		return 37;
	if (color == [OFColor gray])
		return 90;
	if (color == [OFColor red])
		return 91;
	if (color == [OFColor lime])
		return 92;
	if (color == [OFColor yellow])
		return 93;
	if (color == [OFColor blue])
		return 94;
	if (color == [OFColor fuchsia])
		return 95;
	if (color == [OFColor aqua])
		return 96;
	if (color == [OFColor white])
		return 97;

	return -1;
}

static unsigned int
channelTo6Values(uint8_t channel)
{
	if (channel >= 235)
		return 5;
	if (channel >= 195)
		return 4;
	if (channel >= 155)
		return 3;
	if (channel >= 115)
		return 2;
	if (channel >= 75)
		return 1;

	return 0;
}

static unsigned int
colorTo256Color(uint8_t red, uint8_t green, uint8_t blue)
{
	int redIndex, greenIndex, blueIndex;

	if (red == green && green == blue) {
		if (red >= 244)
			return 231;
		if (red >= 234)
			return 255;
		if (red >= 224)
			return 254;
		if (red >= 214)
			return 253;
		if (red >= 204)
			return 252;
		if (red >= 194)
			return 251;
		if (red >= 184)
			return 250;
		if (red >= 174)
			return 249;
		if (red >= 164)
			return 248;
		if (red >= 154)
			return 247;
		if (red >= 144)
			return 246;
		if (red >= 134)
			return 245;
		if (red >= 124)
			return 244;
		if (red >= 114)
			return 243;
		if (red >= 104)
			return 242;
		if (red >= 94)
			return 241;
		if (red >= 84)
			return 240;
		if (red >= 74)
			return 239;
		if (red >= 64)
			return 238;
		if (red >= 54)
			return 237;
		if (red >= 44)
			return 236;
		if (red >= 34)
			return 235;
		if (red >= 24)
			return 234;
		if (red >= 14)
			return 233;
		if (red >= 4)
			return 232;

		return 16;
	}

	redIndex = channelTo6Values(red);
	greenIndex = channelTo6Values(green);
	blueIndex = channelTo6Values(blue);

	return 16 + 36 * redIndex + 6 * greenIndex + blueIndex;
}
#endif

@implementation OFStdIOStream
#ifndef OF_WINDOWS
+ (void)load
{
	if (self != [OFStdIOStream class])
		return;

# if defined(OF_AMIGAOS)
	BPTR input, output, error;
	bool inputClosable = false, outputClosable = false,
	    errorClosable = false;

	input = Input();
	output = Output();
	error = ((struct Process *)FindTask(NULL))->pr_CES;

	if (input == 0) {
		input = Open("*", MODE_OLDFILE);
		inputClosable = true;
	}

	if (output == 0) {
		output = Open("*", MODE_OLDFILE);
		outputClosable = true;
	}

	if (error == 0) {
		error = Open("*", MODE_OLDFILE);
		errorClosable = true;
	}

	OFStdIn = [[OFStdIOStream alloc] of_initWithHandle: input
						  closable: inputClosable];
	OFStdOut = [[OFStdIOStream alloc] of_initWithHandle: output
						   closable: outputClosable];
	OFStdErr = [[OFStdIOStream alloc] of_initWithHandle: error
						   closable: errorClosable];
# elif defined(OF_WII_U)
	OFStdOut = [[OFStdIOStream alloc] of_init];
	OFStdErr = [[OFStdIOStream alloc] of_init];
# else
	int fd;

	if ((fd = fileno(stdin)) >= 0)
		OFStdIn = [[OFStdIOStream alloc] of_initWithFileDescriptor: fd];
	if ((fd = fileno(stdout)) >= 0)
		OFStdOut = [[OFStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = fileno(stderr)) >= 0)
		OFStdErr = [[OFStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
# endif
}
#endif

#if defined(OF_WII)
+ (void)setUpConsole
{
	GXRModeObj *mode;
	void *nextFB;

	VIDEO_Init();

	mode = VIDEO_GetPreferredMode(NULL);
	nextFB = MEM_K0_TO_K1(SYS_AllocateFramebuffer(mode));
	VIDEO_Configure(mode);
	VIDEO_SetNextFramebuffer(nextFB);
	VIDEO_SetBlack(FALSE);
	VIDEO_Flush();

	VIDEO_WaitVSync();
	if (mode->viTVMode & VI_NON_INTERLACE)
		VIDEO_WaitVSync();

	CON_InitEx(mode, 2, 2, mode->fbWidth - 4, mode->xfbHeight - 4);
	VIDEO_ClearFrameBuffer(mode, nextFB, COLOR_BLACK);
}
#elif defined(OF_NINTENDO_DS)
+ (void)setUpConsole
{
	consoleDemoInit();
}
#elif defined(OF_NINTENDO_3DS)
+ (void)setUpConsole
{
	gfxInitDefault();
	atexit(gfxExit);

	consoleInit(GFX_BOTTOM, NULL);
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

#if defined(OF_AMIGAOS)
- (instancetype)of_initWithHandle: (BPTR)handle closable: (bool)closable
{
	self = [super init];

	_handle = handle;
	_closable = closable;
	_colors = 16;
	_cursorVisible = true;

	return self;
}
#elif defined(OF_WII_U)
- (instancetype)of_init
{
	self = [super init];

	_colors = -1;

	return self;
}
#else
- (instancetype)of_initWithFileDescriptor: (int)fd
{
	self = [super init];

	_fd = fd;
# ifdef OF_MSDOS
	_colors = 16;
# else
	_colors = -1;
# endif
	_cursorVisible = self.hasTerminal;

	return self;
}
#endif

- (void)dealloc
{
#if defined(OF_AMIGAOS)
	if (_handle != 0)
		[self close];
#elif !defined(OF_WII_U)
	if (_fd != -1)
		[self close];
#endif

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
#if defined(OF_AMIGAOS)
	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];
#elif !defined(OF_WII_U)
	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];
#endif

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
#if defined(OF_AMIGAOS)
	ssize_t ret;

	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > LONG_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = Read(_handle, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: EIO];

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
#elif defined(OF_WII_U)
	@throw [OFReadFailedException exceptionWithObject: self
					  requestedLength: length
						    errNo: EOPNOTSUPP];
#else
	ssize_t ret;

	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

# ifndef OF_WINDOWS
	if ((ret = read(_fd, buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
# else
	if (length > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = read(_fd, buffer, (unsigned int)length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
# endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
#endif
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
#if defined(OF_AMIGAOS)
	LONG bytesWritten;

	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = Write(_handle, (void *)buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: EIO];

	return (size_t)bytesWritten;
#elif defined(OF_MSDOS)
	ssize_t bytesWritten;

	if (self.hasTerminal) {
		const char *buffer_ = buffer;

		for (size_t i = 0; i < length; i++) {
			if (buffer_[i] == '\n')
				putch('\r');

			putch(buffer_[i]);
		}

		return length;
	}

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_fd, buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];

	return (size_t)bytesWritten;
#elif defined(OF_WII_U)
	OSConsoleWrite(buffer, length);

	return length;
#else
	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

# ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_fd, buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];
# else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_fd, buffer, (int)length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];
# endif

	return (size_t)bytesWritten;
#endif
}

#if !defined(OF_WINDOWS) && !defined(OF_AMIGAOS) && !defined(OF_WII_U)
- (int)fileDescriptorForReading
{
	return _fd;
}

- (int)fileDescriptorForWriting
{
	return _fd;
}
#endif

- (void)close
{
#if defined(OF_AMIGAOS)
	if (_handle == 0)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_closable)
		Close(_handle);

	_handle = 0;
#elif !defined(OF_WII_U)
	if (_fd == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	close(_fd);
	_fd = -1;
#endif

	[super close];
}

- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OFMaxRetainCount;
}

- (bool)hasTerminal
{
#if defined(OF_AMIGAOS)
	return IsInteractive(_handle);
#elif defined(OF_WII) || defined(OF_NINTENDO_DS) || \
    defined(OF_NINTENDO_3DS) || defined(OF_NINTENDO_SWITCH)
	return true;
#elif defined(HAVE_ISATTY) && !defined(OF_WII_U)
	return isatty(_fd);
#else
	return false;
#endif
}

- (int)columns
{
#if defined(OF_MSDOS)
	struct text_info ti;

	gettextinfo(&ti);

	return ti.screenwidth;
#elif defined(HAVE_IOCTL) && defined(TIOCGWINSZ) && \
    !defined(OF_AMIGAOS) && !defined(OF_WII_U)
	struct winsize ws;

	if (ioctl(_fd, TIOCGWINSZ, &ws) != 0)
		return -1;

	return ws.ws_col;
#else
	return -1;
#endif
}

- (int)rows
{
#if defined(OF_MSDOS)
	struct text_info ti;

	gettextinfo(&ti);

	return ti.screenwidth;
#elif defined(HAVE_IOCTL) && defined(TIOCGWINSZ) && \
    !defined(OF_AMIGAOS) && !defined(OF_WII_U)
	struct winsize ws;

	if (ioctl(_fd, TIOCGWINSZ, &ws) != 0)
		return -1;

	return ws.ws_row;
#else
	return -1;
#endif
}

- (int)colors
{
	void *pool;
	OFDictionary OF_GENERIC(OFString *, OFString *) *environment;
	OFString *var;

	if (_colors != -1)
		return _colors;

	if (!self.hasTerminal)
		return -1;

	pool = objc_autoreleasePoolPush();
	environment = [OFApplication environment];

	var = [environment objectForKey: @"COLORTERM"];
	if ([var isEqual: @"24bit"] || [var isEqual: @"truecolor"] ||
	    [var isEqual: @"16777216"]) {
		_colors = 16777216;
		objc_autoreleasePoolPop(pool);
		return _colors;
	}

	var = [environment objectForKey: @"TERM"];
	if ([var hasSuffix: @"-256color"]) {
		_colors = 256;
		objc_autoreleasePoolPop(pool);
		return _colors;
	}

	_colors = 16;
	objc_autoreleasePoolPop(pool);
	return _colors;
}

- (OFColor *)foregroundColor
{
	return _foregroundColor;
}

- (void)setForegroundColor: (OFColor *)color
{
	int code;

	if (color == _foregroundColor)
		return;

	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	if ((code = colorToMSDOS(color, LIGHTGRAY)) == -1)
		return;

	textcolor(code);
#else
	if ((code = colorToANSI(color)) != -1)
		[self writeFormat: @"\033[%um", code];
	else if (self.colors >= 256) {
		float red, green, blue, alpha;
		uint8_t redInt, greenInt, blueInt;

		[color getRed: &red green: &green blue: &blue alpha: &alpha];
		if (alpha != 1 || red < 0 || red > 1 || green < 0 ||
		    green > 1 || blue < 0 || blue > 1)
			return;

		redInt = roundf(red * 255);
		greenInt = roundf(green * 255);
		blueInt = roundf(blue * 255);

		if (self.colors == 16777216)
			[self writeFormat: @"\033[38;2;%u;%u;%um",
					   redInt, greenInt, blueInt];
		else
			[self writeFormat: @"\033[38;5;%um",
					   colorTo256Color(redInt, greenInt,
					       blueInt)];
	}
#endif

	objc_release(_foregroundColor);
	_foregroundColor = objc_retain(color);
}

- (OFColor *)backgroundColor
{
	return _backgroundColor;
}

- (void)setBackgroundColor: (OFColor *)color
{
	int code;

	if (color == _backgroundColor)
		return;

	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	if ((code = colorToMSDOS(color, BLACK)) == -1)
		return;

	textbackground(code);
#else
	if ((code = colorToANSI(color)) != -1)
		[self writeFormat: @"\033[%um", code + 10];
	else {
		float red, green, blue, alpha;
		uint8_t redInt, greenInt, blueInt;

		[color getRed: &red green: &green blue: &blue alpha: &alpha];
		if (alpha != 1 || red < 0 || red > 1 || green < 0 ||
		    green > 1 || blue < 0 || blue > 1)
			return;

		redInt = roundf(red * 255);
		greenInt = roundf(green * 255);
		blueInt = roundf(blue * 255);

		if (self.colors == 16777216)
			[self writeFormat: @"\033[48;2;%u;%u;%um",
					   redInt, greenInt, blueInt];
		else
			[self writeFormat: @"\033[48;5;%um",
					   colorTo256Color(redInt, greenInt,
					       blueInt)];
	}
#endif

	objc_release(_backgroundColor);
	_backgroundColor = objc_retain(color);
}

- (bool)isBold
{
	return _bold;
}

- (void)setBold: (bool)bold
{
#ifndef OF_MSDOS
	if (!self.hasTerminal)
		return;

	if (bold == _bold)
		return;

	[self writeString: (bold ? @"\033[1m" : @"\033[22m")];

	_bold = bold;
#endif
}

- (bool)isItalic
{
	return _italic;
}

- (void)setItalic: (bool)italic
{
#ifndef OF_MSDOS
	if (!self.hasTerminal)
		return;

	if (italic == _italic)
		return;

	[self writeString: (italic ? @"\033[3m" : @"\033[23m")];

	_italic = italic;
#endif
}

- (bool)isUnderlined
{
	return _underlined;
}

- (void)setUnderlined: (bool)underlined
{
#ifndef OF_MSDOS
	if (!self.hasTerminal)
		return;

	if (underlined == _underlined)
		return;

	[self writeString: (underlined ? @"\033[4m" : @"\033[24m")];

	_underlined = underlined;
#endif
}

- (bool)isBlinking
{
	return _blinking;
}

- (void)setBlinking: (bool)blinking
{
#ifndef OF_MSDOS
	if (!self.hasTerminal)
		return;

	if (blinking == _blinking)
		return;

	[self writeString: (blinking ? @"\033[5m" : @"\033[25m")];

	_blinking = blinking;
#endif
}

- (bool)isCursorVisible
{
	return _cursorVisible;
}

- (void)setCursorVisible: (bool)visible
{
	if (!self.hasTerminal)
		return;

	if (visible == _cursorVisible)
		return;

#ifdef OF_MSDOS
	_setcursortype(visible ? _NORMALCURSOR : _NOCURSOR);
#else
	[self writeString: (visible ? @"\033[?25h" : @"\033[?25l")];
#endif

	_cursorVisible = visible;
}

- (void)reset
{
	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	normvideo();
#else
	[self writeString: @"\033[0m"];
#endif

	objc_release(_foregroundColor);
	objc_release(_backgroundColor);
	_foregroundColor = _backgroundColor = nil;
	_bold = false;
	_italic = false;
	_underlined = false;
	_blinking = false;
}

- (void)clear
{
	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	clrscr();
#else
	[self writeString: @"\033[2J"];
#endif
}

- (void)eraseLine
{
	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	int column = wherex();

	gotoxy(1, wherey());
	clreol();
	gotoxy(column, wherey());
#else
	[self writeString: @"\033[2K"];
#endif
}

- (void)setCursorColumn: (unsigned int)column
{
	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	gotoxy(column + 1, wherey());
#else
	if (column == 0)
		[self writeString: @"\r"];
	else
		[self writeFormat: @"\033[%uG", column + 1];
#endif
}

- (void)setCursorPosition: (OFPoint)position
{
	if (position.x < 0 || position.y < 0)
		@throw [OFInvalidArgumentException exception];

	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	gotoxy(position.x + 1, position.y + 1);
#else
	[self writeFormat: @"\033[%u;%uH",
			   (unsigned)position.y + 1, (unsigned)position.x + 1];
#endif
}

- (void)setRelativeCursorPosition: (OFPoint)position
{
	if (!self.hasTerminal)
		return;

#ifdef OF_MSDOS
	gotoxy(wherex() + position.x, wherey() + position.y);
#else
	if (position.x > 0)
		[self writeFormat: @"\033[%uC", (unsigned)position.x];
	else if (position.x < 0)
		[self writeFormat: @"\033[%uD", (unsigned)-position.x];

	if (position.y > 0)
		[self writeFormat: @"\033[%uB", (unsigned)position.y];
	else if (position.y < 0)
		[self writeFormat: @"\033[%uA", (unsigned)-position.y];
#endif
}
@end
