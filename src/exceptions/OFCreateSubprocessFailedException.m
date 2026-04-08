/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFCreateSubprocessFailedException.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFString.h"

@implementation OFCreateSubprocessFailedException
@synthesize program = _program, programName = _programName;
@synthesize arguments = _arguments, environment = _environment, errNo = _errNo;

+ (instancetype)exceptionWithProgram: (OFString *)program
			 programName: (OFString *)programName
			   arguments: (OFArray OF_GENERIC(
					  OFString *) *)arguments
			 environment: (OFDictionary OF_GENERIC(
					  OFString *, OFString *) *)environment
			       errNo: (int)errNo
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithProgram: program
			      programName: programName
				arguments: arguments
			      environment: environment
				    errNo: errNo]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithProgram: (OFString *)program
		    programName: (OFString *)programName
		      arguments: (OFArray OF_GENERIC(OFString *) *)arguments
		    environment: (OFDictionary OF_GENERIC(
				     OFString *, OFString *) *)environment
			  errNo: (int)errNo
{
	self = [super init];

	@try {
		_program = objc_retain(program);
		_programName = objc_retain(_programName);
		_arguments = [arguments copy];
		_environment = [environment copy];
		_errNo = errNo;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_program);
	objc_release(_programName);
	objc_release(_arguments);
	objc_release(_environment);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Failed to create subprocess %@: %@",
	    _program, OFStrError(_errNo)];
}
@end
