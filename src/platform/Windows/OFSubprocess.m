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

#include "config.h"

#include <errno.h>
#include <string.h>

#import "OFSubprocess.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFLocale.h"
#import "OFString.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#include <windows.h>

OF_DIRECT_MEMBERS
@interface OFSubprocess ()
- (OFChar16 *)of_wideEnvironmentForDictionary: (OFDictionary *)dictionary;
- (char *)of_environmentForDictionary: (OFDictionary *)environment;
@end

@implementation OFSubprocess
+ (instancetype)subprocessWithProgram: (OFString *)program
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithProgram: program]);
}

+ (instancetype)subprocessWithProgram: (OFString *)program
			    arguments: (OFArray *)arguments
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithProgram: program
				arguments: arguments]);
}

+ (instancetype)subprocessWithProgram: (OFString *)program
			  programName: (OFString *)programName
			    arguments: (OFArray *)arguments
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithProgram: program
			      programName: programName
				arguments: arguments]);
}

+ (instancetype)subprocessWithProgram: (OFString *)program
			  programName: (OFString *)programName
			    arguments: (OFArray *)arguments
			  environment: (OFDictionary *)environment
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithProgram: program
			      programName: programName
				arguments: arguments
			      environment: environment]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithProgram: (OFString *)program
{
	return [self initWithProgram: program
			 programName: program
			   arguments: nil
			 environment: nil];
}

- (instancetype)initWithProgram: (OFString *)program
		      arguments: (OFArray *)arguments
{
	return [self initWithProgram: program
			 programName: program
			   arguments: arguments
			 environment: nil];
}

- (instancetype)initWithProgram: (OFString *)program
		    programName: (OFString *)programName
		      arguments: (OFArray *)arguments
{
	return [self initWithProgram: program
			 programName: program
			   arguments: arguments
			 environment: nil];
}

- (instancetype)initWithProgram: (OFString *)program
		    programName: (OFString *)programName
		      arguments: (OFArray *)arguments
		    environment: (OFDictionary *)environment
{
	self = [super init];

	@try {
		SECURITY_ATTRIBUTES sa;
		PROCESS_INFORMATION pi;
		void *pool;
		OFMutableString *argumentsString;

		_handle = INVALID_HANDLE_VALUE;
		_readPipe[0] = _writePipe[1] = NULL;

		sa.nLength = sizeof(sa);
		sa.bInheritHandle = TRUE;
		sa.lpSecurityDescriptor = NULL;

		if (!CreatePipe(&_readPipe[0], &_readPipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		if (!SetHandleInformation(_readPipe[0], HANDLE_FLAG_INHERIT, 0))
			if (GetLastError() != ERROR_CALL_NOT_IMPLEMENTED)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];

		if (!CreatePipe(&_writePipe[0], &_writePipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		if (!SetHandleInformation(_writePipe[1],
		    HANDLE_FLAG_INHERIT, 0))
			if (GetLastError() != ERROR_CALL_NOT_IMPLEMENTED)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];

		memset(&pi, 0, sizeof(pi));

		pool = objc_autoreleasePoolPush();

		argumentsString =
		    [OFMutableString stringWithString: programName];
		[argumentsString replaceOccurrencesOfString: @"\\\""
						 withString: @"\\\\\""];
		[argumentsString replaceOccurrencesOfString: @"\""
						 withString: @"\\\""];

		if ([argumentsString containsString: @" "]) {
			[argumentsString insertString: @"\"" atIndex: 0];
			[argumentsString appendString: @"\""];
		}

		for (OFString *argument in arguments) {
			OFMutableString *tmp =
			    objc_autorelease([argument mutableCopy]);
			bool containsSpaces = [tmp containsString: @" "];

			[argumentsString appendString: @" "];

			if (containsSpaces)
				[argumentsString appendString: @"\""];

			[tmp replaceOccurrencesOfString: @"\\\""
					     withString: @"\\\\\""];
			[tmp replaceOccurrencesOfString: @"\""
					     withString: @"\\\""];

			[argumentsString appendString: tmp];

			if (containsSpaces)
				[argumentsString appendString: @"\""];
		}

		if ([OFSystemInfo isWindowsNT]) {
			size_t length;
			OFChar16 *argumentsCopy;
			STARTUPINFOW si;

			memset(&si, 0, sizeof(si));
			si.cb = sizeof(si);
			si.hStdInput = _writePipe[0];
			si.hStdOutput = _readPipe[1];
			si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
			si.dwFlags |= STARTF_USESTDHANDLES;

			length = argumentsString.UTF16StringLength;
			argumentsCopy = OFAllocMemory(length + 1,
			    sizeof(OFChar16));
			memcpy(argumentsCopy, argumentsString.UTF16String,
			    (length + 1) * 2);
			@try {
				if (!CreateProcessW(program.UTF16String,
				    argumentsCopy, NULL, NULL, TRUE,
				    CREATE_UNICODE_ENVIRONMENT,
				    [self of_wideEnvironmentForDictionary:
				    environment], NULL, &si, &pi))
					@throw [OFInitializationFailedException
					    exceptionWithClass: self.class];
			} @finally {
				OFFreeMemory(argumentsCopy);
			}
		} else {
			OFStringEncoding encoding = [OFLocale encoding];
			STARTUPINFO si;

			memset(&si, 0, sizeof(si));
			si.cb = sizeof(si);
			si.hStdInput = _writePipe[0];
			si.hStdOutput = _readPipe[1];
			si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
			si.dwFlags |= STARTF_USESTDHANDLES;

			if (!CreateProcessA([program cStringWithEncoding:
			    encoding], (char *)[argumentsString
			    cStringWithEncoding: encoding], NULL, NULL, TRUE, 0,
			    [self of_environmentForDictionary: environment],
			    NULL, &si, &pi))
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];
		}

		objc_autoreleasePoolPop(pool);

		_handle = pi.hProcess;
		CloseHandle(pi.hThread);

		CloseHandle(_readPipe[1]);
		CloseHandle(_writePipe[0]);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_readPipe[0] != NULL)
		[self close];

	[super dealloc];
}

- (OFChar16 *)of_wideEnvironmentForDictionary: (OFDictionary *)environment
{
	OFMutableData *env;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object;
	const OFChar16 equal = '=';
	const OFChar16 zero[2] = { 0, 0 };

	if (environment == nil)
		return NULL;

	env = [OFMutableData dataWithItemSize: sizeof(OFChar16)];

	keyEnumerator = [environment keyEnumerator];
	objectEnumerator = [environment objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[env addItems: key.UTF16String count: key.UTF16StringLength];
		[env addItems: &equal count: 1];
		[env addItems: object.UTF16String
			count: object.UTF16StringLength];
		[env addItems: &zero count: 1];
	}
	[env addItems: zero count: 2];

	return env.mutableItems;
}

- (char *)of_environmentForDictionary: (OFDictionary *)environment
{
	OFStringEncoding encoding = [OFLocale encoding];
	OFMutableData *env;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object;

	if (environment == nil)
		return NULL;

	env = [OFMutableData data];

	keyEnumerator = [environment keyEnumerator];
	objectEnumerator = [environment objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[env addItems: [key cStringWithEncoding: encoding]
			count: [key cStringLengthWithEncoding: encoding]];
		[env addItems: "=" count: 1];
		[env addItems: [object cStringWithEncoding: encoding]
			count: [object cStringLengthWithEncoding: encoding]];
		[env addItems: "" count: 1];
	}
	[env addItems: "\0" count: 2];

	return env.mutableItems;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_readPipe[0] == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	DWORD ret;

	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if (_readPipe[0] == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!ReadFile(_readPipe[0], buffer, (DWORD)length, &ret, NULL)) {
		if (GetLastError() == ERROR_BROKEN_PIPE) {
			_atEndOfStream = true;
			return 0;
		}

		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: EIO];
	}

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	DWORD bytesWritten;

	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if (_writePipe[1] == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!WriteFile(_writePipe[1], buffer, (DWORD)length, &bytesWritten,
	    NULL)) {
		int errNo = EIO;

		if (GetLastError() == ERROR_BROKEN_PIPE)
			errNo = EPIPE;

		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: errNo];
	}

	return (size_t)bytesWritten;
}

- (void)closeForWriting
{
	if (_readPipe[0] == NULL || _writePipe[1] == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	CloseHandle(_writePipe[1]);

	_writePipe[1] = NULL;
}

- (void)close
{
	if (_readPipe[0] == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_writePipe[1] != NULL)
		[self closeForWriting];

	CloseHandle(_readPipe[0]);

	if (_handle != INVALID_HANDLE_VALUE) {
		TerminateProcess(_handle, 0);
		CloseHandle(_handle);
	}

	_handle = INVALID_HANDLE_VALUE;
	_readPipe[0] = NULL;

	[super close];
}

- (int)waitForTermination
{
	if (_readPipe[0] == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_handle != INVALID_HANDLE_VALUE) {
		DWORD exitCode;

		WaitForSingleObject(_handle, INFINITE);

		if (GetExitCodeProcess(_handle, &exitCode))
			_status = exitCode;
		else
			_status = GetLastError();

		CloseHandle(_handle);
		_handle = INVALID_HANDLE_VALUE;
	}

	return _status;
}
@end
