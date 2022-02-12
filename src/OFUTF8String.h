/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFUTF8String: OFString
{
	/*
	 * A pointer to the actual data.
	 *
	 * Since constant strings don't have `_storage`, they have to allocate
	 * it on the first access. Strings created at runtime just set the
	 * pointer to `&_storage`.
	 */
	struct OFUTF8StringIvars {
		char          *cString;
		size_t        cStringLength;
		bool          isUTF8;
		size_t        length;
		bool          hasHash;
		unsigned long hash;
		bool          freeWhenDone;
	} *restrict _s;
	struct OFUTF8StringIvars _storage;
}
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int OFUTF8StringCheck(const char *, size_t, size_t *);
extern size_t OFUTF8StringIndexToPosition(const char *, size_t, size_t);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
