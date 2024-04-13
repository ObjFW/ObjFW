/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

@class OFIRI;

/**
 * @class OFCreateSymbolicLinkFailedException \
 *	  OFCreateSymbolicLinkFailedException.h \
 *	  ObjFW/OFCreateSymbolicLinkFailedException.h
 *
 * @brief An exception indicating that creating a symbolic link failed.
 */
@interface OFCreateSymbolicLinkFailedException: OFException
{
	OFIRI *_IRI;
	OFString *_target;
	int _errNo;
	OF_RESERVE_IVARS(OFCreateSymbolicLinkFailedException, 4)
}

/**
 * @brief The IRI at which the symbolic link should have been created.
 */
@property (readonly, nonatomic) OFIRI *IRI;

/**
 * @brief The target for the symbolic link.
 */
@property (readonly, nonatomic) OFString *target;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased create symbolic link failed exception.
 *
 * @param IRI The IRI where the symbolic link should have been created
 * @param target The target for the symbolic link
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased create symbolic link failed exception
 */
+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
			  target: (OFString *)target
			   errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated create symbolic link failed
 *	  exception.
 *
 * @param IRI The IRI where the symbolic link should have been created
 * @param target The target for the symbolic link
 * @param errNo The errno of the error that occurred
 * @return An initialized create symbolic link failed exception
 */
- (instancetype)initWithIRI: (OFIRI *)IRI
		     target: (OFString *)target
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
