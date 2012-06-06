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
#import "OFAutoreleasePool.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef _WIN32
# include <windows.h>
#endif

@implementation OFProcess
+ processWithProgram: (OFString*)program
{
	return [[[self alloc] initWithProgram: program] autorelease];
}

+ processWithProgram: (OFString*)program
	   arguments: (OFArray*)arguments
{
	return [[[self alloc] initWithProgram: program
				    arguments: arguments] autorelease];
}

+ processWithProgram: (OFString*)program
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
			    exceptionWithClass: isa];

		switch ((pid = fork())) {
		case 0:;
			OFString **objects = [arguments objects];
			size_t i, count = [arguments count];
			char **argv;

			argv = [self allocMemoryWithItemSize: sizeof(char*)
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
			    exceptionWithClass: isa];
		case -1:
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];
		default:
			close(readPipe[1]);
			close(writePipe[0]);
			break;
		}
#else
		SECURITY_ATTRIBUTES sa;
		PROCESS_INFORMATION pi;
		STARTUPINFO si;
		OFAutoreleasePool *pool;
		OFMutableString *argumentsString;
		OFEnumerator *enumerator;
		OFString *argument;
		char *argumentsCString;

		sa.nLength = sizeof(sa);
		sa.bInheritHandle = TRUE;
		sa.lpSecurityDescriptor = NULL;

		if (!CreatePipe(&readPipe[0], &readPipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		if (!SetHandleInformation(readPipe[0], HANDLE_FLAG_INHERIT, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		if (!CreatePipe(&writePipe[0], &writePipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		if (!SetHandleInformation(writePipe[1], HANDLE_FLAG_INHERIT, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		memset(&pi, 0, sizeof(pi));
		memset(&si, 0, sizeof(si));

		si.cb = sizeof(si);
		si.hStdInput = writePipe[0];
		si.hStdOutput = readPipe[1];
		si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
		si.dwFlags |= STARTF_USESTDHANDLES;

		pool = [[OFAutoreleasePool alloc] init];

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
				    exceptionWithClass: isa];
		} @finally {
			free(argumentsString);
		}

		[pool release];

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

- (BOOL)_isAtEndOfStream
{
#ifndef _WIN32
	if (readPipe[0] == -1)
#else
	if (readPipe[0] == NULL)
#endif
		return YES;

	return atEndOfStream;
}

- (size_t)_readNBytes: (size_t)length
	   intoBuffer: (void*)buffer
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
		@throw [OFReadFailedException exceptionWithClass: isa
							  stream: self
						 requestedLength: length];
	}

	if (ret == 0)
		atEndOfStream = YES;

	return ret;
}

- (void)_writeNBytes: (size_t)length
	  fromBuffer: (const void*)buffer
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
		@throw [OFWriteFailedException exceptionWithClass: isa
							   stream: self
						  requestedLength: length];
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

/*
 * FIXME: Add -[fileDescriptor]. The problem is that we have two FDs, which is
 *	  not yet supported by OFStreamObserver. This has to be split into one
 *	  FD for reading and one for writing.
 */

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
