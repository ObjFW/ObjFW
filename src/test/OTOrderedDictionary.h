/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 */
@interface OTOrderedDictionary: OFDictionary
{
	OFArray *_keys;
	OFArray *_objects;
}
@end

OF_ASSUME_NONNULL_END
