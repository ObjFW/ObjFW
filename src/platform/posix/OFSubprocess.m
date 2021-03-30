/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include <signal.h>

#ifdef HAVE_SYS_WAIT_H
# include <sys/wait.h>
#endif

#include "unistd_wrapper.h"
#ifdef HAVE_SPAWN_H
# include <spawn.h>
#endif

#import "OFSubprocess.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFLocale.h"

#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifndef HAVE_POSIX_SPAWNP
extern char **environ;
#endif

@interface OFSubprocess ()
- (void)of_getArgv: (char ***)argv
    forProgramName: (OFString *)programName
      andArguments: (OFArray *)arguments;
- (char **)of_environmentForDictionary: (OFDictionary *)dictionary;
@end

@implementation OFSubprocess
+ (instancetype)subprocessWithProgram: (OFString *)program
{
	return [[[self alloc] initWithProgram: program] autorelease];
}

+ (instancetype)subprocessWithProgram: (OFString *)program
			    arguments: (OFArray *)arguments
{
	return [[[self alloc] initWithProgram: program
				    arguments: arguments] autorelease];
}

+ (instancetype)subprocessWithProgram: (OFString *)program
			  programName: (OFString *)programName
			    arguments: (OFArray *)arguments
{
	return [[[self alloc] initWithProgram: program
				  programName: programName
				    arguments: arguments] autorelease];
}

+ (instancetype)subprocessWithProgram: (OFString *)program
			  programName: (OFString *)programName
			    arguments: (OFArray *)arguments
			  environment: (OFDictionary *)environment
{
	return [[[self alloc] initWithProgram: program
				  programName: programName
				    arguments: arguments
				  environment: environment] autorelease];
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
		void *pool = objc_autoreleasePoolPush();
		const char *path;
		char **argv, **env = NULL;

		_pid = -1;
		_readPipe[0] = _writePipe[1] = -1;

		if (pipe(_readPipe) != 0 || pipe(_writePipe) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		path = [program cStringWithEncoding: [OFLocale encoding]];
		[self of_getArgv: &argv
		  forProgramName: programName
		    andArguments: arguments];

		@try {
			env = [self of_environmentForDictionary: environment];
#ifdef HAVE_POSIX_SPAWNP
			posix_spawn_file_actions_t actions;
			posix_spawnattr_t attr;

			if (posix_spawn_file_actions_init(&actions) != 0)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];

			if (posix_spawnattr_init(&attr) != 0) {
				posix_spawn_file_actions_destroy(&actions);

				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];
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
					    exceptionWithClass: self.class];

# ifdef POSIX_SPAWN_CLOEXEC_DEFAULT
				if (posix_spawnattr_setflags(&attr,
				    POSIX_SPAWN_CLOEXEC_DEFAULT) != 0)
					@throw [OFInitializationFailedException
					    exceptionWithClass: self.class];
# endif

				if (posix_spawnp(&_pid, path, &actions, &attr,
				    argv, env) != 0)
					@throw [OFInitializationFailedException
					    exceptionWithClass: self.class];
			} @finally {
				posix_spawn_file_actions_destroy(&actions);
				posix_spawnattr_destroy(&attr);
			}
#else
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
				    exceptionWithClass: self.class];
#endif
		} @finally {
			char **iter;

			close(_readPipe[1]);
			close(_writePipe[0]);
			free(argv);

			for (iter = env; *iter != NULL; iter++)
				free(*iter);

			free(env);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_readPipe[0] != -1)
		[self close];

	[super dealloc];
}

- (void)of_getArgv: (char ***)argv
    forProgramName: (OFString *)programName
      andArguments: (OFArray *)arguments
{
	OFString *const *objects = arguments.objects;
	size_t i, count = arguments.count;
	of_string_encoding_t encoding;

	*argv = of_alloc(count + 2, sizeof(char *));

	encoding = [OFLocale encoding];

	(*argv)[0] = (char *)[programName cStringWithEncoding: encoding];

	for (i = 0; i < count; i++)
		(*argv)[i + 1] =
		    (char *)[objects[i] cStringWithEncoding: encoding];

	(*argv)[i + 1] = NULL;
}

- (char **)of_environmentForDictionary: (OFDictionary *)environment
{
	char **envp;
	size_t count;
	of_string_encoding_t encoding;

	if (environment == nil)
		return NULL;

	encoding = [OFLocale encoding];

	count = environment.count;
	envp = of_alloc_zeroed(count + 1, sizeof(char *));

	@try {
		OFEnumerator *keyEnumerator = [environment keyEnumerator];
		OFEnumerator *objectEnumerator = [environment objectEnumerator];

		for (size_t i = 0; i < count; i++) {
			OFString *key;
			OFString *object;
			size_t keyLen, objectLen;

			key = [keyEnumerator nextObject];
			object = [objectEnumerator nextObject];

			keyLen = [key cStringLengthWithEncoding: encoding];
			objectLen = [object
			    cStringLengthWithEncoding: encoding];

			envp[i] = of_alloc(keyLen + objectLen + 2, 1);

			memcpy(envp[i],
			    [key cStringWithEncoding: encoding], keyLen);
			envp[i][keyLen] = '=';
			memcpy(envp[i] + keyLen + 1,
			    [object cStringWithEncoding: encoding], objectLen);
			envp[i][keyLen + objectLen + 1] = '\0';
		}
	} @catch (id e) {
		for (size_t i = 0; i < count; i++)
			free(envp[i]);

		free(envp);

		@throw e;
	}

	return envp;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_readPipe[0] == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_readPipe[0] == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = read(_readPipe[0], buffer, length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: errno];

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	ssize_t bytesWritten;

	if (_writePipe[1] == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = write(_writePipe[1], buffer, length)) < 0)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: errno];

	return (size_t)bytesWritten;
}

- (int)fileDescriptorForReading
{
	return _readPipe[0];
}

- (int)fileDescriptorForWriting
{
	return _writePipe[1];
}

- (void)closeForWriting
{
	if (_writePipe[1] != -1)
		close(_writePipe[1]);

	_writePipe[1] = -1;
}

- (void)close
{
	if (_readPipe[0] == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	[self closeForWriting];
	close(_readPipe[0]);

	if (_pid != -1) {
		kill(_pid, SIGTERM);
		waitpid(_pid, &_status, WNOHANG);
	}

	_pid = -1;
	_readPipe[0] = -1;

	[super close];
}

- (int)waitForTermination
{
	if (_readPipe[0] == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_pid != -1) {
		waitpid(_pid, &_status, 0);
		_pid = -1;
	}

	return WEXITSTATUS(_status);
}
@end
