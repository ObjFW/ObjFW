/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFUTF8String: OFString
{
@public
	/*
	 * A pointer to the actual data.
	 *
	 * Since constant strings don't have `_storage`, they have to allocate
	 * it on the first access. Strings created at runtime just set the
	 * pointer to `&_storage`.
	 */
	struct of_string_utf8_ivars {
		char	 *cString;
		size_t	 cStringLength;
		bool	 isUTF8;
		size_t	 length;
		bool	 hashed;
		uint32_t hash;
		char	 *_Nullable freeWhenDone;
	} *restrict _s;
	struct of_string_utf8_ivars _storage;
}
@end

#ifdef __cplusplus
extern "C" {
#endif
extern int of_string_utf8_check(const char *, size_t, size_t *);
extern size_t of_string_utf8_get_index(const char *, size_t);
extern size_t of_string_utf8_get_position(const char *, size_t, size_t);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
