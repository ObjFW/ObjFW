/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include "objfw-defs.h"

#ifdef OF_HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#import "OFStream.h"
#import "OFString.h"

#ifdef OF_WINDOWS
# include <windows.h>
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/*!
 * @class OFProcess OFProcess.h ObjFW/OFProcess.h
 *
 * @brief A class for stream-like communication with a newly created process.
 */
@interface OFProcess: OFStream
{
#ifndef OF_WINDOWS
	pid_t _pid;
	int _readPipe[2], _writePipe[2];
#else
	HANDLE _process, _readPipe[2], _writePipe[2];
#endif
	int _status;
	bool _atEndOfStream;
}

/*!
 * @brief Creates a new OFProcess with the specified program and invokes the
 *	  program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @return A new, autoreleased OFProcess.
 */
+ (instancetype)processWithProgram: (OFString *)program;

/*!
 * @brief Creates a new OFProcess with the specified program and arguments and
 *	  invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @param arguments The arguments to pass to the program, or `nil`
 * @return A new, autoreleased OFProcess.
 */
+ (instancetype)
    processWithProgram: (OFString *)program
	     arguments: (nullable OFArray OF_GENERIC(OFString *) *)arguments;

/*!
 * @brief Creates a new OFProcess with the specified program, program name and
 *	  arguments and invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @param programName The program name for the program to invoke (argv[0]).
 *		      Usually, this is equal to program.
 * @param arguments The arguments to pass to the program, or `nil`
 * @return A new, autoreleased OFProcess.
 */
+ (instancetype)
    processWithProgram: (OFString *)program
	   programName: (OFString *)programName
	     arguments: (nullable OFArray OF_GENERIC(OFString *) *)arguments;

/*!
 * @brief Creates a new OFProcess with the specified program, program name,
 *	  arguments and environment and invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @param programName The program name for the program to invoke (argv[0]).
 *		      Usually, this is equal to program.
 * @param arguments The arguments to pass to the program, or `nil`
 * @param environment The environment to pass to the program, or `nil`. If it
 *		      is not `nil`, the passed dictionary will be used to
 *		      override the environment. If you want to add to the
 *		      existing environment, you need to get the existing
 *		      environment first, copy it, modify it and then pass it.
 * @return A new, autoreleased OFProcess.
 */
+ (instancetype)
    processWithProgram: (OFString *)program
	   programName: (OFString *)programName
	     arguments: (nullable OFArray OF_GENERIC(OFString *) *)arguments
	   environment: (nullable OFDictionary
			    OF_GENERIC(OFString *, OFString *) *)environment;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFProcess with the specified program
 *	  and invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @return An initialized OFProcess.
 */
- (instancetype)initWithProgram: (OFString *)program;

/*!
 * @brief Initializes an already allocated OFProcess with the specified program
 *	  and arguments and invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @param arguments The arguments to pass to the program, or `nil`
 * @return An initialized OFProcess.
 */
- (instancetype)
    initWithProgram: (OFString *)program
	  arguments: (nullable OFArray OF_GENERIC(OFString *) *)arguments;

/*!
 * @brief Initializes an already allocated OFProcess with the specified program,
 *	  program name and arguments and invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @param programName The program name for the program to invoke (argv[0]).
 *		      Usually, this is equal to program.
 * @param arguments The arguments to pass to the program, or `nil`
 * @return An initialized OFProcess.
 */
- (instancetype)
    initWithProgram: (OFString *)program
	programName: (OFString *)programName
	  arguments: (nullable OFArray OF_GENERIC(OFString *) *)arguments;

/*!
 * @brief Initializes an already allocated OFProcess with the specified program,
 *	  program name, arguments and environment and invokes the program.
 *
 * @param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * @param programName The program name for the program to invoke (argv[0]).
 *		      Usually, this is equal to program.
 * @param arguments The arguments to pass to the program, or `nil`
 * @param environment The environment to pass to the program, or `nil`. If it
 *		      is not `nil`, the passed dictionary will be used to
 *		      override the environment. If you want to add to the
 *		      existing environment, you need to get the existing
 *		      environment first, copy it, modify it and then pass it.
 * @return An initialized OFProcess.
 */
- (instancetype)
    initWithProgram: (OFString *)program
	programName: (OFString *)programName
	  arguments: (nullable OFArray OF_GENERIC(OFString *) *)arguments
	environment: (nullable OFDictionary
			 OF_GENERIC(OFString *, OFString *) *)environment
    OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Closes the write direction of the process.
 *
 * This method needs to be called for some programs before data can be read,
 * since some programs don't start processing before the write direction is
 * closed.
 */
- (void)closeForWriting;
@end

OF_ASSUME_NONNULL_END
