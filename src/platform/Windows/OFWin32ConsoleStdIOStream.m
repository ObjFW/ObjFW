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

/*
 * This file tries to make writing UTF-8 strings to the console "just work" on
 * Windows.
 *
 * While Windows does provide a way to change the codepage of the console to
 * UTF-8, unfortunately, different Windows versions handle that differently.
 * For example, on Windows XP, when using Windows XP's console, changing the
 * codepage to UTF-8 mostly breaks write() and completely breaks read():
 * write() suddenly returns the number of characters - instead of bytes -
 * written and read() just returns 0 as soon as a Unicode character is being
 * read.
 *
 * Therefore, instead of just using the UTF-8 codepage, this captures all reads
 * and writes to OFStd{In,Out,Err} on the low level, interprets the buffer as
 * UTF-8 and converts to / from UTF-16 to use ReadConsoleW() / WriteConsoleW().
 * Doing so is safe, as the console only supports text anyway and thus it does
 * not matter if binary gets garbled by the conversion (e.g. because invalid
 * UTF-8 gets converted to U+FFFD).
 *
 * In order to not do this when redirecting input / output to a file (as the
 * file would then be read / written in the wrong encoding and break reading /
 * writing binary), it checks that the handle is indeed a console.
 */

#include "config.h"

#include <errno.h>
#include <io.h>

#import "OFWin32ConsoleStdIOStream.h"
#import "OFColor.h"
#import "OFData.h"
#import "OFStdIOStream+Private.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#include <windows.h>

static OFStringEncoding
codepageToEncoding(UINT codepage)
{
	switch (codepage) {
	case 437:
		return OFStringEncodingCodepage437;
	case 850:
		return OFStringEncodingCodepage850;
	case 858:
		return OFStringEncodingCodepage858;
	case 1250:
		return OFStringEncodingWindows1250;
	case 1251:
		return OFStringEncodingWindows1251;
	case 1252:
		return OFStringEncodingWindows1252;
	default:
		@throw [OFInvalidEncodingException exception];
	}
}

@implementation OFWin32ConsoleStdIOStream
+ (void)load
{
	int fd;

	if (self != [OFWin32ConsoleStdIOStream class])
		return;

	if ((fd = _fileno(stdin)) >= 0)
		OFStdIn = [[OFWin32ConsoleStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = _fileno(stdout)) >= 0)
		OFStdOut = [[OFWin32ConsoleStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = _fileno(stderr)) >= 0)
		OFStdErr = [[OFWin32ConsoleStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
}

- (instancetype)of_initWithFileDescriptor: (int)fd
{
	self = [super of_initWithFileDescriptor: fd];

	@try {
		DWORD mode;
		CONSOLE_SCREEN_BUFFER_INFO csbi;

		_handle = (HANDLE)_get_osfhandle(fd);
		if (_handle == INVALID_HANDLE_VALUE)
			@throw [OFInvalidArgumentException exception];

		/* Not a console: Treat it as a regular OFStdIOStream */
		if (!GetConsoleMode(_handle, &mode))
			object_setClass(self, [OFStdIOStream class]);

		if (GetConsoleScreenBufferInfo(_handle, &csbi))
			_attributes = csbi.wAttributes;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer_ length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	char *buffer = buffer_;
	OFChar16 *UTF16;
	size_t j = 0;

	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	UTF16 = OFAllocMemory(length, sizeof(OFChar16));
	@try {
		DWORD UTF16Len;
		OFMutableData *rest = nil;
		size_t i = 0;

		if ([OFSystemInfo isWindowsNT]) {
			if (!ReadConsoleW(_handle, UTF16, (DWORD)length,
			    &UTF16Len, NULL))
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: length * 2
						  errNo: EIO];
		} else {
			OFStringEncoding encoding;
			OFString *string;
			size_t stringLen;

			if (!ReadConsoleA(_handle, (char *)UTF16, (DWORD)length,
			    &UTF16Len, NULL))
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: length
						  errNo: EIO];

			encoding = codepageToEncoding(GetConsoleCP());
			string = [OFString stringWithCString: (char *)UTF16
						    encoding: encoding
						      length: UTF16Len];
			stringLen = string.UTF16StringLength;

			if (stringLen > length)
				@throw [OFOutOfRangeException exception];

			UTF16Len = (DWORD)stringLen;
			memcpy(UTF16, string.UTF16String, stringLen);
		}

		if (UTF16Len > 0 && _incompleteUTF16Surrogate != 0) {
			OFUnichar c =
			    (((_incompleteUTF16Surrogate & 0x3FF) << 10) |
			    (UTF16[0] & 0x3FF)) + 0x10000;
			char UTF8[4];
			size_t UTF8Len;

			if ((UTF8Len = _OFUTF8StringEncode(c, UTF8)) == 0)
				@throw [OFInvalidEncodingException exception];

			if (UTF8Len <= length) {
				memcpy(buffer, UTF8, UTF8Len);
				j += UTF8Len;
			} else {
				if (rest == nil)
					rest = [OFMutableData data];

				[rest addItems: UTF8 count: UTF8Len];
			}

			_incompleteUTF16Surrogate = 0;
			i++;
		}

		for (; i < UTF16Len; i++) {
			OFUnichar c = UTF16[i];
			char UTF8[4];
			size_t UTF8Len;

			/* Missing high surrogate */
			if ((c & 0xFC00) == 0xDC00)
				@throw [OFInvalidEncodingException exception];

			if ((c & 0xFC00) == 0xD800) {
				OFChar16 next;

				if (UTF16Len <= i + 1) {
					_incompleteUTF16Surrogate = c;

					if (rest != nil) {
						const char *items = rest.items;
						size_t count = rest.count;

						[self unreadFromBuffer: items
								length: count];
					}

					objc_autoreleasePoolPop(pool);

					return j;
				}

				next = UTF16[i + 1];

				if ((next & 0xFC00) != 0xDC00)
					@throw [OFInvalidEncodingException
					    exception];

				c = (((c & 0x3FF) << 10) | (next & 0x3FF)) +
				    0x10000;

				i++;
			}

			if ((UTF8Len = _OFUTF8StringEncode(c, UTF8)) == 0)
				@throw [OFInvalidEncodingException exception];

			if (j + UTF8Len <= length) {
				memcpy(buffer + j, UTF8, UTF8Len);
				j += UTF8Len;
			} else {
				if (rest == nil)
					rest = [OFMutableData data];

				[rest addItems: UTF8 count: UTF8Len];
			}
		}

		if (rest != nil)
			[self unreadFromBuffer: rest.items length: rest.count];
	} @finally {
		OFFreeMemory(UTF16);
	}

	objc_autoreleasePoolPop(pool);

	return j;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer_ length: (size_t)length
{
	const char *buffer = buffer_;
	OFChar16 *tmp;
	size_t i = 0, j = 0;

	if (length > SIZE_MAX / 2)
		@throw [OFOutOfRangeException exception];

	if (_incompleteUTF8SurrogateLen > 0) {
		OFUnichar c;
		OFChar16 UTF16[2];
		ssize_t UTF8Len;
		size_t toCopy;
		DWORD UTF16Len, bytesWritten;

		UTF8Len = -_OFUTF8StringDecode(
		    _incompleteUTF8Surrogate, _incompleteUTF8SurrogateLen, &c);

		OFEnsure(UTF8Len > 0);

		toCopy = UTF8Len - _incompleteUTF8SurrogateLen;
		if (toCopy > length)
			toCopy = length;

		memcpy(_incompleteUTF8Surrogate + _incompleteUTF8SurrogateLen,
		    buffer, toCopy);
		_incompleteUTF8SurrogateLen += toCopy;

		if (_incompleteUTF8SurrogateLen < (size_t)UTF8Len)
			return 0;

		UTF8Len = _OFUTF8StringDecode(
		    _incompleteUTF8Surrogate, _incompleteUTF8SurrogateLen, &c);

		if (UTF8Len <= 0 || c > 0x10FFFF) {
			OFAssert(UTF8Len == 0 || UTF8Len < -4);

			UTF16[0] = 0xFFFD;
			UTF16Len = 1;
		} else {
			if (c > 0xFFFF) {
				c -= 0x10000;
				UTF16[0] = 0xD800 | (c >> 10);
				UTF16[1] = 0xDC00 | (c & 0x3FF);
				UTF16Len = 2;
			} else {
				UTF16[0] = c;
				UTF16Len = 1;
			}
		}

		if ([OFSystemInfo isWindowsNT]) {
			if (!WriteConsoleW(_handle, UTF16, UTF16Len,
			    &bytesWritten, NULL))
				@throw [OFWriteFailedException
				    exceptionWithObject: self
					requestedLength: UTF16Len * 2
					   bytesWritten: bytesWritten * 2
						  errNo: EIO];
		} else {
			void *pool = objc_autoreleasePoolPush();
			OFString *string = [OFString
			    stringWithUTF16String: UTF16
					   length: UTF16Len];
			OFStringEncoding encoding =
			    codepageToEncoding(GetConsoleOutputCP());
			size_t nativeLen = [string
			    cStringLengthWithEncoding: encoding];

			if (nativeLen > UINT32_MAX)
				@throw [OFOutOfRangeException exception];

			if (!WriteConsoleA(_handle,
			    [string cStringWithEncoding: encoding],
			    (DWORD)nativeLen, &bytesWritten, NULL))
				@throw [OFWriteFailedException
				    exceptionWithObject: self
					requestedLength: nativeLen
					   bytesWritten: bytesWritten
						  errNo: EIO];

			objc_autoreleasePoolPop(pool);
		}

		if (bytesWritten != UTF16Len)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: UTF16Len * 2
				   bytesWritten: bytesWritten * 2
					  errNo: 0];

		_incompleteUTF8SurrogateLen = 0;
		i += toCopy;
	}

	tmp = OFAllocMemory(length * 2, sizeof(OFChar16));
	@try {
		DWORD bytesWritten;

		while (i < length) {
			OFUnichar c;
			ssize_t UTF8Len;

			UTF8Len = _OFUTF8StringDecode(buffer + i, length - i,
			    &c);

			if (UTF8Len < 0 && UTF8Len >= -4) {
				OFEnsure(length - i < 4);

				memcpy(_incompleteUTF8Surrogate, buffer + i,
				    length - i);
				_incompleteUTF8SurrogateLen = length - i;

				break;
			}

			if (UTF8Len <= 0 || c > 0x10FFFF) {
				tmp[j++] = 0xFFFD;
				i++;
				continue;
			}

			if (c > 0xFFFF) {
				c -= 0x10000;
				tmp[j++] = 0xD800 | (c >> 10);
				tmp[j++] = 0xDC00 | (c & 0x3FF);
			} else
				tmp[j++] = c;

			i += UTF8Len;
		}

		if (j > UINT32_MAX)
			@throw [OFOutOfRangeException exception];

		if ([OFSystemInfo isWindowsNT]) {
			if (!WriteConsoleW(_handle, tmp, (DWORD)j,
			    &bytesWritten, NULL))
				@throw [OFWriteFailedException
				    exceptionWithObject: self
					requestedLength: j * 2
					   bytesWritten: bytesWritten * 2
						  errNo: EIO];
		} else {
			void *pool = objc_autoreleasePoolPush();
			OFString *string = [OFString stringWithUTF16String: tmp
								    length: j];
			OFStringEncoding encoding =
			    codepageToEncoding(GetConsoleOutputCP());
			size_t nativeLen = [string
			    cStringLengthWithEncoding: encoding];

			if (nativeLen > UINT32_MAX)
				@throw [OFOutOfRangeException exception];

			if (!WriteConsoleA(_handle,
			    [string cStringWithEncoding: encoding],
			    (DWORD)nativeLen, &bytesWritten, NULL))
				@throw [OFWriteFailedException
				    exceptionWithObject: self
					requestedLength: nativeLen
					   bytesWritten: bytesWritten
						  errNo: EIO];

			objc_autoreleasePoolPop(pool);
		}

		if (bytesWritten != j)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: j * 2
				   bytesWritten: bytesWritten * 2
					  errNo: 0];
	} @finally {
		OFFreeMemory(tmp);
	}

	/*
	 * We do not count in bytes when writing to the Win32 console. But
	 * since any incomplete write is an exception here anyway, we can just
	 * return length.
	 */
	return length;
}

- (bool)hasTerminal
{
	/*
	 * We can never get here if there is no terminal, as the initializer
	 * changes the class to OFStdIOStream in that case.
	 */
	return true;
}

- (int)columns
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return -1;

	return csbi.dwSize.X;
}

- (int)rows
{
	/*
	 * The buffer size returned is almost always larger than the window
	 * size, so this is useless.
	 */
	return -1;
}

- (void)setForegroundColor: (OFColor *)color
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	float red, green, blue;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return;

	csbi.wAttributes &= ~(FOREGROUND_RED | FOREGROUND_GREEN |
	    FOREGROUND_BLUE | FOREGROUND_INTENSITY);

	[color getRed: &red green: &green blue: &blue alpha: NULL];

	if (red >= 0.25)
		csbi.wAttributes |= FOREGROUND_RED;
	if (green >= 0.25)
		csbi.wAttributes |= FOREGROUND_GREEN;
	if (blue >= 0.25)
		csbi.wAttributes |= FOREGROUND_BLUE;

	if (red >= 0.75 || green >= 0.75 || blue >= 0.75)
		csbi.wAttributes |= FOREGROUND_INTENSITY;

	SetConsoleTextAttribute(_handle, csbi.wAttributes);
}

- (void)setBackgroundColor: (OFColor *)color
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	float red, green, blue;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return;

	csbi.wAttributes &= ~(BACKGROUND_RED | BACKGROUND_GREEN |
	    BACKGROUND_BLUE | BACKGROUND_INTENSITY);

	[color getRed: &red green: &green blue: &blue alpha: NULL];

	if (red >= 0.25)
		csbi.wAttributes |= BACKGROUND_RED;
	if (green >= 0.25)
		csbi.wAttributes |= BACKGROUND_GREEN;
	if (blue >= 0.25)
		csbi.wAttributes |= BACKGROUND_BLUE;

	if (red >= 0.75 || green >= 0.75 || blue >= 0.75)
		csbi.wAttributes |= BACKGROUND_INTENSITY;

	SetConsoleTextAttribute(_handle, csbi.wAttributes);
}

- (void)reset
{
	SetConsoleTextAttribute(_handle, _attributes);
}

- (void)clear
{
	static COORD zero = { 0, 0 };
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	DWORD bytesWritten;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return;

	if (!FillConsoleOutputCharacter(_handle, ' ',
	    csbi.dwSize.X * csbi.dwSize.Y, zero, &bytesWritten))
		return;

	if (!FillConsoleOutputAttribute(_handle, csbi.wAttributes,
	    csbi.dwSize.X * csbi.dwSize.Y, zero, &bytesWritten))
		return;

	SetConsoleCursorPosition(_handle, zero);
}

- (void)eraseLine
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	DWORD bytesWritten;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return;

	csbi.dwCursorPosition.X = 0;

	if (!FillConsoleOutputCharacter(_handle, ' ', csbi.dwSize.X,
		csbi.dwCursorPosition, &bytesWritten))
		return;

	FillConsoleOutputAttribute(_handle, csbi.wAttributes, csbi.dwSize.X,
	    csbi.dwCursorPosition, &bytesWritten);
}

- (void)setCursorColumn: (unsigned int)column
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return;

	csbi.dwCursorPosition.X = column;

	SetConsoleCursorPosition(_handle, csbi.dwCursorPosition);
}

- (void)setCursorPosition: (OFPoint)position
{
	if (position.x < 0 || position.y < 0)
		@throw [OFInvalidArgumentException exception];

	SetConsoleCursorPosition(_handle, (COORD){ position.x, position.y });
}

- (void)setRelativeCursorPosition: (OFPoint)position
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;

	if (!GetConsoleScreenBufferInfo(_handle, &csbi))
		return;

	csbi.dwCursorPosition.X += position.x;
	csbi.dwCursorPosition.Y += position.y;

	SetConsoleCursorPosition(_handle, csbi.dwCursorPosition);
}
@end
