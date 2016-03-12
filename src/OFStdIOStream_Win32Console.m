/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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
 * Windows does provide a way to change the codepage of the console to UTF-8,
 * but unfortunately, different Windows versions handle that differently. For
 * example on Windows XP when using Windows XP's console, changing the codepage
 * to UTF-8 mostly breaks write() and completely breaks read(): write()
 * suddenly returns the number of characters - instead of bytes - written and
 * read() just returns 0 as soon as a Unicode character is being read.
 *
 * So instead of just using the UTF-8 codepage, this captures all reads and
 * writes to of_std{in,err,out} on the lowlevel, interprets the buffer as UTF-8
 * and converts to / from UTF-16 to use ReadConsoleW() and WriteConsoleW(), as
 * reading or writing binary from / to the console would not make any sense
 * anyway and thus it's safe to assume it's text.
 *
 * In order to not do this when redirecting input / output to a file, it checks
 * that the handle is indeed a console.
 *
 * TODO: Properly handle surrogates being cut in the middle
 */

#define OF_STDIO_STREAM_WIN32_CONSOLE_M

#include "config.h"

#import "OFStdIOStream_Win32Console.h"
#import "OFStdIOStream+Private.h"
#import "OFDataArray.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#include <windows.h>

@implementation OFStdIOStream_Win32Console
+ (void)load
{
	of_stdin = [[OFStdIOStream_Win32Console alloc]
	    OF_initWithFileDescriptor: 0];
	of_stdout = [[OFStdIOStream_Win32Console alloc]
	    OF_initWithFileDescriptor: 1];
	of_stderr = [[OFStdIOStream_Win32Console alloc]
	    OF_initWithFileDescriptor: 2];
}

- (instancetype)OF_initWithFileDescriptor: (int)fd
{
	self = [super OF_initWithFileDescriptor: fd];

	@try {
		DWORD mode;

		switch (fd) {
		case 0:
			_handle = GetStdHandle(STD_INPUT_HANDLE);
			break;
		case 1:
			_handle = GetStdHandle(STD_OUTPUT_HANDLE);
			break;
		case 2:
			_handle = GetStdHandle(STD_ERROR_HANDLE);
			break;
		default:
			@throw [OFInvalidArgumentException exception];
		}

		/* Not a console: Treat it as a regular OFStdIOStream */
		if (!GetConsoleMode(_handle, &mode))
			object_setClass(self, [OFStdIOStream class]);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer_
			  length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	char *buffer = buffer_;
	of_char16_t *UTF16;
	size_t j = 0;
	OFDataArray *rest = nil;

	UTF16 = [self allocMemoryWithSize: sizeof(of_char16_t)
				    count: length];
	@try {
		DWORD UTF16Len;

		if (!ReadConsoleW(_handle, UTF16, length, &UTF16Len, NULL))
			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: length];

		for (size_t i = 0; i < UTF16Len; i++) {
			of_unichar_t c = UTF16[i];
			char UTF8[4];
			size_t UTF8Len;

			/* Missing high surrogate */
			if ((c & 0xFC00) == 0xDC00)
				@throw [OFInvalidEncodingException exception];

			if ((c & 0xFC00) == 0xD800) {
				of_char16_t next;

				if (UTF16Len <= i + 1)
					@throw [OFInvalidEncodingException
					    exception];

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
					rest = [OFDataArray dataArray];

				[rest addItems: UTF8
					 count: UTF8Len];
			}
		}

		if (rest != nil)
			[self unreadFromBuffer: [rest items]
					length: [rest count]];
	} @finally {
		[self freeMemory: UTF16];
	}

	objc_autoreleasePoolPop(pool);

	return j;
}

- (void)lowlevelWriteBuffer: (const void*)buffer_
		     length: (size_t)length
{
	const char *buffer = buffer_;
	of_char16_t *tmp;

	if (length > SIZE_MAX / 2)
		@throw [OFOutOfRangeException exception];

	tmp = [self allocMemoryWithSize: sizeof(of_char16_t)
				  count: length * 2];
	@try {
		size_t i = 0, j = 0;
		DWORD written;

		while (i < length) {
			of_unichar_t c;
			size_t cLen;

			cLen = of_string_utf8_decode(buffer + i, length - i,
			    &c);

			if (cLen == 0 || c > 0x10FFFF)
				@throw [OFInvalidEncodingException exception];

			if (c > 0xFFFF) {
				c -= 0x10000;
				tmp[j++] = 0xD800 | (c >> 10);
				tmp[j++] = 0xDC00 | (c & 0x3FF);
			} else
				tmp[j++] = c;

			i += cLen;
		}

		if (!WriteConsoleW(_handle, tmp, j, &written, NULL) ||
		    written != j)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: j];
	} @finally {
		[self freeMemory: tmp];
	}
}
@end
