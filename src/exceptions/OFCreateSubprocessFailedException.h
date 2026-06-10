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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/**
 * @class OFCreateSubprocessFailedException
 *	  OFCreateSubprocessFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that creating a subprocess failed.
 */
@interface OFCreateSubprocessFailedException: OFException
{
	OFString *_program, *_programName;
	OFArray OF_GENERIC(OFString *) *_Nullable _arguments;
	OFDictionary OF_GENERIC(OFString *, OFString *) *_Nullable _environment;
	int _errNo;
	OF_RESERVE_IVARS(OFCreateSubprocessFailedException, 4)
}

/**
 * @brief The program that could not be invoked.
 */
@property (readonly, nonatomic) OFString *program;

/**
 * @brief The program name for the program that could not be invoked.
 */
@property (readonly, nonatomic) OFString *programName;

/**
 * @brief The arguments passed to the program that could not be invoked.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFArray OF_GENERIC(OFString *) *arguments;

/**
 * @brief The enviroment passed to the program that could not be invoked.
 */
@property OF_NULLABLE_PROPERTY (readonly, copy, nonatomic)
    OFDictionary OF_GENERIC(OFString *, OFString *) *environment;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased create subprocess failed key failed
 *	  exception.
 *
 * @param program The program that could not be invoked
 * @param programName The program name for the program that could not be invoked
 * @param arguments The arguments passed to the program that could not be
 *		    invoked
 * @param environment The enviroment passed to the program that could not be
 *		      invoked
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased creates subprocess failed exception
 */
+ (instancetype)exceptionWithProgram: (OFString *)program
			 programName: (OFString *)programName
			   arguments: (nullable OFArray OF_GENERIC(
					  OFString *) *)arguments
			 environment: (nullable OFDictionary OF_GENERIC(
					  OFString *, OFString *) *)environment
			       errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated create subprocess failed exception.
 *
 * @param program The program that could not be invoked
 * @param programName The program name for the program that could not be invoked
 * @param arguments The arguments passed to the program that could not be
 *		    invoked
 * @param environment The enviroment passed to the program that could not be
 *		      invoked
 * @param errNo The errno of the error that occurred
 * @return An initialized create subprocess failed exception
 */
- (instancetype)initWithProgram: (OFString *)program
		    programName: (OFString *)programName
		      arguments: (nullable OFArray OF_GENERIC(
				     OFString *) *)arguments
		    environment: (nullable OFDictionary OF_GENERIC(
				     OFString *, OFString *) *)environment
			  errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
