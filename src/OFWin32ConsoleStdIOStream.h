/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#define OF_WIN32_CONSOLE_STDIO_STREAM_H
#import "OFStdIOStream.h"
#undef OF_WIN32_CONSOLE_STDIO_STREAM_H

OF_ASSUME_NONNULL_BEGIN

@interface OFWin32ConsoleStdIOStream: OFStdIOStream
{
	HANDLE _handle;
	WORD _attributes;
	OFChar16 _incompleteUTF16Surrogate;
	char _incompleteUTF8Surrogate[4];
	size_t _incompleteUTF8SurrogateLen;
}
@end

OF_ASSUME_NONNULL_END
