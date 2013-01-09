/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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
#include <string.h>

#ifndef _WIN32
# include <unistd.h>
# include <signal.h>
# include <sys/wait.h>
#endif

#ifdef __MACH__
# include <crt_externs.h>
#endif

#import "OFProcess.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFDataArray.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef _WIN32
# include <windows.h>
#endif

#import "autorelease.h"

#ifndef __MACH__
extern char **environ;
#endif

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

+ (instancetype)processWithProgram: (OFString*)program
		       programName: (OFString*)programName
			 arguments: (OFArray*)arguments
		       environment: (OFDictionary*)environment
{
	return [[[self alloc] initWithProgram: program
				  programName: programName
				    arguments: arguments
				  environment: environment] autorelease];
}

- initWithProgram: (OFString*)program
{
	return [self initWithProgram: program
			 programName: program
			   arguments: nil
			 environment: nil];
}

- initWithProgram: (OFString*)program
	arguments: (OFArray*)arguments
{
	return [self initWithProgram: program
			 programName: program
			   arguments: arguments
			 environment: nil];
}

- initWithProgram: (OFString*)program
      programName: (OFString*)programName
	arguments: (OFArray*)arguments
{
	return [self initWithProgram: program
			 programName: program
			   arguments: arguments
			 environment: nil];
}

- initWithProgram: (OFString*)program
      programName: (OFString*)programName
	arguments: (OFArray*)arguments
      environment: (OFDictionary*)environment
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

			argv[0] = (char*)[programName cStringUsingEncoding:
			    OF_STRING_ENCODING_NATIVE];

			for (i = 0; i < count; i++)
				argv[i + 1] = (char*)[objects[i]
				    cStringUsingEncoding:
				    OF_STRING_ENCODING_NATIVE];

			argv[i + 1] = NULL;

			if (environment != nil) {
#ifdef __MACH__
				*_NSGetEnviron() = [self
				    OF_environmentForDictionary: environment];
#else
				environ = [self
				    OF_environmentForDictionary: environment];
#endif
			}

			close(readPipe[0]);
			close(writePipe[1]);
			dup2(writePipe[0], 0);
			dup2(readPipe[1], 1);
			execvp([program cStringUsingEncoding:
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
		STARTUPINFOW si;
		void *pool;
		OFMutableString *argumentsString;
		OFEnumerator *enumerator;
		OFString *argument;
		uint16_t *argumentsCopy;
		size_t length;

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

		length = [argumentsString UTF16StringLength];
		argumentsCopy = [self allocMemoryWithSize: sizeof(uint16_t)
						    count: length + 1];
		memcpy(argumentsCopy, [argumentsString UTF16String],
		    ([argumentsString UTF16StringLength] + 1) * 2);
		@try {
			if (!CreateProcessW([program UTF16String],
			    argumentsCopy, NULL, NULL, TRUE,
			    CREATE_UNICODE_ENVIRONMENT,
			    [self OF_environmentForDictionary: environment],
			    NULL, &si, &pi))
				@throw [OFInitializationFailedException
				    exceptionWithClass: [self class]];
		} @finally {
			[self freeMemory: argumentsCopy];
		}

		objc_autoreleasePoolPop(pool);

		process = pi.hProcess;
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

#ifndef _WIN32
- (char**)OF_environmentForDictionary: (OFDictionary*)environment
{
	OFEnumerator *keyEnumerator, *objectEnumerator;
	char **envp;
	size_t i, count;

	if (environment == nil)
		return NULL;

	count = [environment count];
	envp = [self allocMemoryWithSize: sizeof(char*)
				   count: count + 1];

	keyEnumerator = [environment keyEnumerator];
	objectEnumerator = [environment objectEnumerator];

	for (i = 0; i < count; i++) {
		OFString *key;
		OFString *object;
		size_t keyLen, objectLen;

		key = [keyEnumerator nextObject];
		object = [objectEnumerator nextObject];

		keyLen = [key lengthOfBytesUsingEncoding:
		    OF_STRING_ENCODING_NATIVE];
		objectLen = [object lengthOfBytesUsingEncoding:
		    OF_STRING_ENCODING_NATIVE];

		envp[i] = [self allocMemoryWithSize: keyLen + objectLen + 2];

		memcpy(envp[i], [key cStringUsingEncoding:
		    OF_STRING_ENCODING_NATIVE], keyLen);
		envp[i][keyLen] = '=';
		memcpy(envp[i] + keyLen + 1, [object cStringUsingEncoding:
		    OF_STRING_ENCODING_NATIVE], objectLen);
		envp[i][keyLen + objectLen + 1] = '\0';
	}

	envp[i] = NULL;

	return envp;
}
#else
- (uint16_t*)OF_environmentForDictionary: (OFDictionary*)environment
{
	OFDataArray *env = [OFDataArray dataArrayWithItemSize: 2];
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object;
	const uint16_t equal = '=';
	const uint16_t zero = 0;

	keyEnumerator = [environment keyEnumerator];
	objectEnumerator = [environment objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[env addItems: [key UTF16String]
			count: [key UTF16StringLength]];
		[env addItems: &equal
			count: 1];
		[env addItems: [object UTF16String]
			count: [object UTF16StringLength]];
		[env addItems: &zero
			count: 1];
	}
	[env addItems: &zero
		count: 1];

	return [env items];
}
#endif

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
	[self doesNotRecognizeSelector: _cmd];
	abort();
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef _WIN32
	return writePipe[1];
#else
	[self doesNotRecognizeSelector: _cmd];
	abort();
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

	if (pid != -1) {
		kill(pid, SIGKILL);
		waitpid(pid, &status, WNOHANG);
	}

	pid = -1;
	readPipe[0] = -1;
	writePipe[1] = -1;
#else
	if (readPipe[0] != NULL)
		CloseHandle(readPipe[0]);
	if (writePipe[1] != NULL)
		CloseHandle(writePipe[1]);

	if (process != INVALID_HANDLE_VALUE) {
		TerminateProcess(process, 0);
		CloseHandle(process);
	}

	process = INVALID_HANDLE_VALUE;
	readPipe[0] = NULL;
	writePipe[1] = NULL;
#endif
}
@end
