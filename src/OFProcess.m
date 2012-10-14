/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include "config.h"

#include <stdlib.h>

#ifndef _WIN32
# include <unistd.h>
# include <sys/wait.h>
#endif

#import "OFProcess.h"
#import "OFString.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef _WIN32
# include <windows.h>
#endif

#import "autorelease.h"

@implementation OFProcess
+ (instancetype)processWithProgram: (OFString*)program
{
	return [[[self alloc] initWithProgram: program] autorelease];
}

+ (instancetype)processWithProgram: (OFString*)program
			 arguments: (OFArray*)arguments
{
	return [[[self alloc] initWithProgram: program
				    arguments: arguments] autorelease];
}

+ (instancetype)processWithProgram: (OFString*)program
		       programName: (OFString*)programName
			 arguments: (OFArray*)arguments
{
	return [[[self alloc] initWithProgram: program
				  programName: programName
				    arguments: arguments] autorelease];
}

- initWithProgram: (OFString*)program
{
	return [self initWithProgram: program
			 programName: program
			   arguments: nil];
}

- initWithProgram: (OFString*)program
	arguments: (OFArray*)arguments
{
	return [self initWithProgram: program
			 programName: program
			   arguments: arguments];
}

- initWithProgram: (OFString*)program
      programName: (OFString*)programName
	arguments: (OFArray*)arguments
{
	self = [super init];

	@try {
#ifndef _WIN32
		if (pipe(readPipe) != 0 || pipe(writePipe) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		switch ((pid = fork())) {
		case 0:;
			OFString **objects = [arguments objects];
			size_t i, count = [arguments count];
			char **argv;

			argv = [self allocMemoryWithSize: sizeof(char*)
						   count: count + 2];

			argv[0] = (char*)[programName cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE];

			for (i = 0; i < count; i++)
				argv[i + 1] = (char*)[objects[i]
				    cStringWithEncoding:
				    OF_STRING_ENCODING_NATIVE];

			argv[i + 1] = NULL;

			close(readPipe[0]);
			close(writePipe[1]);
			dup2(writePipe[0], 0);
			dup2(readPipe[1], 1);
			execvp([program cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE], argv);

			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
		case -1:
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
		default:
			close(readPipe[1]);
			close(writePipe[0]);
			break;
		}
#else
		SECURITY_ATTRIBUTES sa;
		PROCESS_INFORMATION pi;
		STARTUPINFO si;
		void *pool;
		OFMutableString *argumentsString;
		OFEnumerator *enumerator;
		OFString *argument;
		char *argumentsCString;

		sa.nLength = sizeof(sa);
		sa.bInheritHandle = TRUE;
		sa.lpSecurityDescriptor = NULL;

		if (!CreatePipe(&readPipe[0], &readPipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if (!SetHandleInformation(readPipe[0], HANDLE_FLAG_INHERIT, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if (!CreatePipe(&writePipe[0], &writePipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if (!SetHandleInformation(writePipe[1], HANDLE_FLAG_INHERIT, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		memset(&pi, 0, sizeof(pi));
		memset(&si, 0, sizeof(si));

		si.cb = sizeof(si);
		si.hStdInput = writePipe[0];
		si.hStdOutput = readPipe[1];
		si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
		si.dwFlags |= STARTF_USESTDHANDLES;

		pool = objc_autoreleasePoolPush();

		argumentsString =
		    [OFMutableString stringWithString: programName];
		[argumentsString replaceOccurrencesOfString: @"\\\""
						 withString: @"\\\\\""];
		[argumentsString replaceOccurrencesOfString: @"\""
						 withString: @"\\\""];

		if ([argumentsString containsString: @" "]) {
			[argumentsString prependString: @"\""];
			[argumentsString appendString: @"\""];
		}

		enumerator = [arguments objectEnumerator];
		while ((argument = [enumerator nextObject]) != nil) {
			OFMutableString *tmp =
			    [[argument mutableCopy] autorelease];
			BOOL containsSpaces = [tmp containsString: @" "];

			[argumentsString appendString: @" "];

			if (containsSpaces)
				[argumentsString appendString: @"\""];

			[tmp replaceOccurrencesOfString: @"\\\""
					     withString: @"\\\\\""];
			[tmp replaceOccurrencesOfString: @"\""
					     withString: @"\\\""];;

			[argumentsString appendString: tmp];

			if (containsSpaces)
				[argumentsString appendString: @"\""];
		}

		argumentsCString = strdup([argumentsString
		    cStringWithEncoding: OF_STRING_ENCODING_NATIVE]);
		@try {
			if (!CreateProcess([program cStringWithEncoding:
			    OF_STRING_ENCODING_NATIVE], argumentsCString, NULL,
			    NULL, TRUE, 0, NULL, NULL, &si, &pi))
				@throw [OFInitializationFailedException
				    exceptionWithClass: [self class]];
		} @finally {
			free(argumentsString);
		}

		objc_autoreleasePoolPop(pool);

		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);

		CloseHandle(readPipe[1]);
		CloseHandle(writePipe[0]);
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (BOOL)lowlevelIsAtEndOfStream
{
#ifndef _WIN32
	if (readPipe[0] == -1)
#else
	if (readPipe[0] == NULL)
#endif
		return YES;

	return atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
#ifndef _WIN32
	ssize_t ret;
#else
	DWORD ret;
#endif

#ifndef _WIN32
	if (readPipe[0] == -1 || atEndOfStream ||
	    (ret = read(readPipe[0], buffer, length)) < 0) {
#else
	if (readPipe[0] == NULL || atEndOfStream ||
	    !ReadFile(readPipe[0], buffer, length, &ret, NULL)) {
		if (GetLastError() == ERROR_BROKEN_PIPE) {
			atEndOfStream = YES;
			return 0;
		}

#endif
		@throw [OFReadFailedException exceptionWithClass: [self class]
							  stream: self
						 requestedLength: length];
	}

	if (ret == 0)
		atEndOfStream = YES;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
#ifndef _WIN32
	if (writePipe[1] == -1 || atEndOfStream ||
	    write(writePipe[1], buffer, length) < length)
#else
	DWORD ret;

	if (writePipe[1] == NULL || atEndOfStream ||
	    !WriteFile(writePipe[1], buffer, length, &ret, NULL) ||
	    ret < length)
#endif
		@throw [OFWriteFailedException exceptionWithClass: [self class]
							   stream: self
						  requestedLength: length];
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (int)fileDescriptorForReading
{
#ifndef _WIN32
	return readPipe[0];
#else
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef _WIN32
	return writePipe[1];
#else
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
#endif
}

- (void)closeForWriting
{
#ifndef _WIN32
	if (writePipe[1] != -1)
		close(writePipe[1]);

	writePipe[1] = -1;
#else
	if (writePipe[1] != NULL)
		CloseHandle(writePipe[1]);

	writePipe[1] = NULL;
#endif
}

- (void)close
{
#ifndef _WIN32
	if (readPipe[0] != -1)
		close(readPipe[0]);
	if (writePipe[1] != -1)
		close(writePipe[1]);

	if (pid != -1)
		waitpid(pid, &status, WNOHANG);

	pid = -1;
	readPipe[0] = -1;
	writePipe[1] = -1;
#else
	if (readPipe[0] != NULL)
		CloseHandle(readPipe[0]);
	if (writePipe[1] != NULL)
		CloseHandle(writePipe[1]);

	readPipe[0] = NULL;
	writePipe[1] = NULL;
#endif
}
@end
