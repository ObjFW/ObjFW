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

#define OF_STDIO_STREAM_WIN32CONSOLE_H

#import "OFStdIOStream.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFWin32ConsoleStdIOStream: OFStdIOStream
{
	HANDLE _handle;
	of_char16_t _incompleteUTF16Surrogate;
	char _incompleteUTF8Surrogate[4];
	size_t _incompleteUTF8SurrogateLen;
}
@end

OF_ASSUME_NONNULL_END
