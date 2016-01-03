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

#include "config.h"

#include <errno.h>
#include <string.h>

/* Work around __block being used by glibc */
#ifdef __GLIBC__
# undef __USE_XOPEN
#endif

#ifndef _WIN32
# include <unistd.h>
# include <signal.h>
# include <sys/wait.h>
#endif

#ifdef HAVE_SPAWN_H
# include <spawn.h>
#endif

#import "OFProcess.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef _WIN32
# include <windows.h>
#endif

#ifndef __MACH__
extern char **environ;
#endif

@interface OFProcess (OF_PRIVATE_CATEGORY)
#ifndef _WIN32
- (void)OF_getArgV: (char***)argv
    forProgramName: (OFString*)programName
      andArguments: (OFArray*)arguments;
- (char**)OF_environmentForDictionary: (OFDictionary*)dictionary;
#else
- (of_char16_t*)OF_environmentForDictionary: (OFDictionary*)dictionary;
#endif
@end

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

- init
{
	OF_INVALID_INIT_METHOD
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
		void *pool = objc_autoreleasePoolPush();
		const char *path;
		char **argv;

		if (pipe(_readPipe) != 0 || pipe(_writePipe) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		path = [program cStringWithEncoding:
		    [OFSystemInfo native8BitEncoding]];
		[self OF_getArgV: &argv
		  forProgramName: programName
		    andArguments: arguments];

		@try {
			char **env = [self
			    OF_environmentForDictionary: environment];
# ifdef HAVE_POSIX_SPAWNP
			posix_spawn_file_actions_t actions;
			posix_spawnattr_t attr;

			if (posix_spawn_file_actions_init(&actions) != 0)
				@throw [OFInitializationFailedException
				    exceptionWithClass: [self class]];

			if (posix_spawnattr_init(&attr) != 0) {
				posix_spawn_file_actions_destroy(&actions);

				@throw [OFInitializationFailedException
				    exceptionWithClass: [self class]];
			}

			@try {
				if (posix_spawn_file_actions_addclose(&actions,
				    _readPipe[0]) != 0 ||
				    posix_spawn_file_actions_addclose(&actions,
				    _writePipe[1]) != 0 ||
				    posix_spawn_file_actions_adddup2(&actions,
				    _writePipe[0], 0) != 0 ||
				    posix_spawn_file_actions_adddup2(&actions,
				    _readPipe[1], 1) != 0)
					@throw [OFInitializationFailedException
					    exceptionWithClass: [self class]];

#  ifdef POSIX_SPAWN_CLOEXEC_DEFAULT
				if (posix_spawnattr_setflags(&attr,
				    POSIX_SPAWN_CLOEXEC_DEFAULT) != 0)
					@throw [OFInitializationFailedException
					    exceptionWithClass: [self class]];
#  endif

				if (posix_spawnp(&_pid, path, &actions, &attr,
				    argv, env) != 0)
					@throw [OFInitializationFailedException
					    exceptionWithClass: [self class]];
			} @finally {
				posix_spawn_file_actions_destroy(&actions);
				posix_spawnattr_destroy(&attr);
			}
# else
			if ((_pid = vfork()) == 0) {
				environ = env;

				close(_readPipe[0]);
				close(_writePipe[1]);
				dup2(_writePipe[0], 0);
				dup2(_readPipe[1], 1);
				execvp(path, argv);

				_exit(EXIT_FAILURE);
			}

			if (_pid == -1)
				@throw [OFInitializationFailedException
				    exceptionWithClass: [self class]];
# endif
		} @finally {
			close(_readPipe[1]);
			close(_writePipe[0]);
			[self freeMemory: argv];
		}

		objc_autoreleasePoolPop(pool);
#else
		SECURITY_ATTRIBUTES sa;
		PROCESS_INFORMATION pi;
		STARTUPINFOW si;
		void *pool;
		OFMutableString *argumentsString;
		OFEnumerator *enumerator;
		OFString *argument;
		of_char16_t *argumentsCopy;
		size_t length;

		sa.nLength = sizeof(sa);
		sa.bInheritHandle = TRUE;
		sa.lpSecurityDescriptor = NULL;

		if (!CreatePipe(&_readPipe[0], &_readPipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if (!SetHandleInformation(_readPipe[0], HANDLE_FLAG_INHERIT, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if (!CreatePipe(&_writePipe[0], &_writePipe[1], &sa, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if (!SetHandleInformation(_writePipe[1],
		    HANDLE_FLAG_INHERIT, 0))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		memset(&pi, 0, sizeof(pi));
		memset(&si, 0, sizeof(si));

		si.cb = sizeof(si);
		si.hStdInput = _writePipe[0];
		si.hStdOutput = _readPipe[1];
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

		length = [argumentsString UTF16StringLength];
		argumentsCopy = [self allocMemoryWithSize: sizeof(of_char16_t)
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

		_process = pi.hProcess;
		CloseHandle(pi.hThread);

		CloseHandle(_readPipe[1]);
		CloseHandle(_writePipe[0]);
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

#ifndef _WIN32
- (void)OF_getArgV: (char***)argv
    forProgramName: (OFString*)programName
      andArguments: (OFArray*)arguments
{
	OFString *const *objects = [arguments objects];
	size_t i, count = [arguments count];
	of_string_encoding_t encoding;

	*argv = [self allocMemoryWithSize: sizeof(char*)
				    count: count + 2];

	encoding = [OFSystemInfo native8BitEncoding];

	(*argv)[0] = (char*)[programName cStringWithEncoding: encoding];

	for (i = 0; i < count; i++)
		(*argv)[i + 1] =
		    (char*)[objects[i] cStringWithEncoding: encoding];

	(*argv)[i + 1] = NULL;
}

- (char**)OF_environmentForDictionary: (OFDictionary*)environment
{
	OFEnumerator *keyEnumerator, *objectEnumerator;
	char **envp;
	size_t i, count;
	of_string_encoding_t encoding;

	if (environment == nil)
		return NULL;

	encoding = [OFSystemInfo native8BitEncoding];

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

		keyLen = [key cStringLengthWithEncoding: encoding];
		objectLen = [object cStringLengthWithEncoding: encoding];

		envp[i] = [self allocMemoryWithSize: keyLen + objectLen + 2];

		memcpy(envp[i], [key cStringWithEncoding: encoding], keyLen);
		envp[i][keyLen] = '=';
		memcpy(envp[i] + keyLen + 1,
		    [object cStringWithEncoding: encoding], objectLen);
		envp[i][keyLen + objectLen + 1] = '\0';
	}

	envp[i] = NULL;

	return envp;
}
#else
- (of_char16_t*)OF_environmentForDictionary: (OFDictionary*)environment
{
	OFDataArray *env = [OFDataArray dataArrayWithItemSize: 2];
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object;
	const of_char16_t equal = '=';
	const of_char16_t zero = 0;

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

- (bool)lowlevelIsAtEndOfStream
{
#ifndef _WIN32
	if (_readPipe[0] == -1)
#else
	if (_readPipe[0] == NULL)
#endif
		return true;

	return _atEndOfStream;
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
	if (_readPipe[0] == -1 || _atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

	if ((ret = read(_readPipe[0], buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];
#else
	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if (_readPipe[0] == NULL || _atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

	if (!ReadFile(_readPipe[0], buffer, (DWORD)length, &ret, NULL)) {
		if (GetLastError() == ERROR_BROKEN_PIPE) {
			_atEndOfStream = true;
			return 0;
		}

		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];
	}
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
#ifndef _WIN32
	if (_writePipe[1] == -1 || _atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (write(_writePipe[1], buffer, length) != (ssize_t)length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errno];
#else
	DWORD ret;

	if (length > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if (_writePipe[1] == NULL || _atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];

	if (!WriteFile(_writePipe[1], buffer, (DWORD)length, &ret, NULL) ||
	    ret != (DWORD)length) {
		int errNo = 0;

		if (GetLastError() == ERROR_BROKEN_PIPE)
			errNo = EPIPE;

		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: errNo];
	}
#endif
}

- (int)fileDescriptorForReading
{
#ifndef _WIN32
	return _readPipe[0];
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef _WIN32
	return _writePipe[1];
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (void)closeForWriting
{
#ifndef _WIN32
	if (_writePipe[1] != -1)
		close(_writePipe[1]);

	_writePipe[1] = -1;
#else
	if (_writePipe[1] != NULL)
		CloseHandle(_writePipe[1]);

	_writePipe[1] = NULL;
#endif
}

- (void)close
{
#ifndef _WIN32
	if (_readPipe[0] != -1)
		close(_readPipe[0]);
	if (_writePipe[1] != -1)
		close(_writePipe[1]);

	if (_pid != -1) {
		kill(_pid, SIGTERM);
		waitpid(_pid, &_status, WNOHANG);
	}

	_pid = -1;
	_readPipe[0] = -1;
	_writePipe[1] = -1;
#else
	if (_readPipe[0] != NULL)
		CloseHandle(_readPipe[0]);
	if (_writePipe[1] != NULL)
		CloseHandle(_writePipe[1]);

	if (_process != INVALID_HANDLE_VALUE) {
		TerminateProcess(_process, 0);
		CloseHandle(_process);
	}

	_process = INVALID_HANDLE_VALUE;
	_readPipe[0] = NULL;
	_writePipe[1] = NULL;
#endif
}
@end
