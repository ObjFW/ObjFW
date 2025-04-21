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

#ifdef OBJFWTEST_LOCAL_INCLUDES
# import "ObjFW.h"
#else
# import <ObjFW/ObjFW.h>
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A dictionary that enumerates keys and objects in the same order they
 *	  were specified during initialization.
 *
 * @warning This class is only for testing! It is slow and only to be used to
 *	    test extensions of OFDictionary, for example serializations such as
 *	    JSON, where it is desirable to compare to an expected output.
 *
 * @note ABI stability for this and all other classes in ObjFWTest is not
 *	 guaranteed! The assumption is that you recompile your tests after
 *	 updating ObjFWTest.
 */
@interface OTOrderedDictionary: OFDictionary
{
	OFArray *_keys;
	OFArray *_objects;
}
@end

OF_ASSUME_NONNULL_END
