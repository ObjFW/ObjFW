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
 * and writes to of_std{in,out,err} on the low level, interprets the buffer as
 * UTF-8 and converts to / from UTF-16 to use ReadConsoleW() / WriteConsoleW().
 * Doing so is safe, as the console only supports text anyway and thus it does
 * not matter if binary gets garbled by the conversion (e.g. because invalid
 * UTF-8 gets converted to U+FFFD).
 *
 * In order to not do this when redirecting input / output to a file (as the
 * file would then be read / written in the wrong encoding and break reading /
 * writing binary), it checks that the handle is indeed a console.
 */

#define OF_STDIO_STREAM_WIN32_CONSOLE_M

#include "config.h"

#include <assert.h>
#include <errno.h>
#include <io.h>

#import "OFWin32ConsoleStdIOStream.h"
#import "OFData.h"
#import "OFStdIOStream+Private.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#include <windows.h>

@implementation OFWin32ConsoleStdIOStream
+ (void)load
{
	int fd;

	if (self != [OFWin32ConsoleStdIOStream class])
		return;

	if ((fd = _fileno(stdin)) >= 0)
		of_stdin = [[OFWin32ConsoleStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = _fileno(stdout)) >= 0)
		of_stdout = [[OFWin32ConsoleStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
	if ((fd = _fileno(stderr)) >= 0)
		of_stderr = [[OFWin32ConsoleStdIOStream alloc]
		    of_initWithFileDescriptor: fd];
}

- (instancetype)of_initWithFileDescriptor: (int)fd
{
	self = [super of_initWithFileDescriptor: fd];

	@try {
		DWORD mode;

		_handle = (HANDLE)_get_osfhandle(fd);
		if (_handle == INVALID_HANDLE_VALUE)
			@throw [OFInvalidArgumentException exception];

		/* Not a console: Treat it as a regular OFStdIOStream */
		if (!GetConsoleMode(_handle, &mode))
			object_setClass(self, [OFStdIOStream class]);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer_
			  length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	char *buffer = buffer_;
	of_char16_t *UTF16;
	size_t j = 0;

	if (length > sizeof(UINT32_MAX))
		@throw [OFOutOfRangeException exception];

	UTF16 = [self allocMemoryWithSize: sizeof(of_char16_t)
				    count: length];
	@try {
		DWORD UTF16Len;
		OFMutableData *rest = nil;
		size_t i = 0;

		if (!ReadConsoleW(_handle, UTF16, (DWORD)length, &UTF16Len,
		    NULL))
			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: length * 2
					  errNo: EIO];

		if (UTF16Len > 0 && _incompleteUTF16Surrogate != 0) {
			of_unichar_t c =
			    (((_incompleteUTF16Surrogate & 0x3FF) << 10) |
			    (UTF16[0] & 0x3FF)) + 0x10000;
			char UTF8[4];
			size_t UTF8Len;

			if ((UTF8Len = of_string_utf8_encode(c, UTF8)) == 0)
				@throw [OFInvalidEncodingException exception];

			if (UTF8Len <= length) {
				memcpy(buffer, UTF8, UTF8Len);
				j += UTF8Len;
			} else {
				if (rest == nil)
					rest = [OFMutableData data];

				[rest addItems: UTF8
					 count: UTF8Len];
			}

			_incompleteUTF16Surrogate = 0;
			i++;
		}

		for (; i < UTF16Len; i++) {
			of_unichar_t c = UTF16[i];
			char UTF8[4];
			size_t UTF8Len;

			/* Missing high surrogate */
			if ((c & 0xFC00) == 0xDC00)
				@throw [OFInvalidEncodingException exception];

			if ((c & 0xFC00) == 0xD800) {
				of_char16_t next;

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

			if ((UTF8Len = of_string_utf8_encode(c, UTF8)) == 0)
				@throw [OFInvalidEncodingException exception];

			if (j + UTF8Len <= length) {
				memcpy(buffer + j, UTF8, UTF8Len);
				j += UTF8Len;
			} else {
				if (rest == nil)
					rest = [OFMutableData data];

				[rest addItems: UTF8
					 count: UTF8Len];
			}
		}

		if (rest != nil)
			[self unreadFromBuffer: rest.items
					length: rest.count];
	} @finally {
		[self freeMemory: UTF16];
	}

	objc_autoreleasePoolPop(pool);

	return j;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer_
		       length: (size_t)length
{
	const char *buffer = buffer_;
	of_char16_t *tmp;
	size_t i = 0, j = 0;

	if (length > SIZE_MAX / 2)
		@throw [OFOutOfRangeException exception];

	if (_incompleteUTF8SurrogateLen > 0) {
		of_unichar_t c;
		of_char16_t UTF16[2];
		ssize_t UTF8Len;
		size_t toCopy;
		DWORD UTF16Len, bytesWritten;

		UTF8Len = -of_string_utf8_decode(
		    _incompleteUTF8Surrogate, _incompleteUTF8SurrogateLen, &c);

		OF_ENSURE(UTF8Len > 0);

		toCopy = UTF8Len - _incompleteUTF8SurrogateLen;
		if (toCopy > length)
			toCopy = length;

		memcpy(_incompleteUTF8Surrogate + _incompleteUTF8SurrogateLen,
		    buffer, toCopy);
		_incompleteUTF8SurrogateLen += toCopy;

		if (_incompleteUTF8SurrogateLen < (size_t)UTF8Len)
			return 0;

		UTF8Len = of_string_utf8_decode(
		    _incompleteUTF8Surrogate, _incompleteUTF8SurrogateLen, &c);

		if (UTF8Len <= 0 || c > 0x10FFFF) {
			assert(UTF8Len == 0 || UTF8Len < -4);

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

		if (!WriteConsoleW(_handle, UTF16, UTF16Len, &bytesWritten,
		    NULL))
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: UTF16Len * 2
				   bytesWritten: 0
					  errNo: EIO];

		if (bytesWritten != UTF16Len)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: UTF16Len * 2
				   bytesWritten: bytesWritten * 2
					  errNo: 0];

		_incompleteUTF8SurrogateLen = 0;
		i += toCopy;
	}

	tmp = [self allocMemoryWithSize: sizeof(of_char16_t)
				  count: length * 2];
	@try {
		DWORD bytesWritten;

		while (i < length) {
			of_unichar_t c;
			ssize_t UTF8Len;

			UTF8Len = of_string_utf8_decode(buffer + i, length - i,
			    &c);

			if (UTF8Len < 0 && UTF8Len >= -4) {
				OF_ENSURE(length - i < 4);

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

		if (!WriteConsoleW(_handle, tmp, (DWORD)j, &bytesWritten, NULL))
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: j * 2
				   bytesWritten: 0
					  errNo: EIO];

		if (bytesWritten != j)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: j * 2
				   bytesWritten: bytesWritten * 2
					  errNo: 0];
	} @finally {
		[self freeMemory: tmp];
	}

	/*
	 * We do not count in bytes when writing to the Win32 console. But
	 * since any incomplete write is an exception here anyway, we can just
	 * return length.
	 */
	return length;
}
@end
