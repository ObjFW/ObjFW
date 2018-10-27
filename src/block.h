/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "macros.h"

OF_ASSUME_NONNULL_BEGIN

typedef struct of_block_literal_t {
#ifdef __OBJC__
	Class isa;
#else
	void *isa;
#endif
	int flags;
	int reserved;
	void (*invoke)(void *block, ...);
	struct of_block_descriptor_t {
		unsigned long reserved;
		unsigned long size;
		void (*_Nullable copy_helper)(void *dest, void *src);
		void (*_Nullable dispose_helper)(void *src);
		const char *signature;
	} *descriptor;
} of_block_literal_t;

#ifdef __cplusplus
extern "C" {
#endif
extern void *_Block_copy(const void *);
extern void _Block_release(const void *);

# if defined(OF_WINDOWS) && \
    (defined(OF_NO_SHARED) || defined(OF_COMPILING_OBJFW))
/*
 * Clang has implicit declarations for these, but they are dllimport. When
 * compiling ObjFW itself or using it as a static library, these need to be
 * dllexport. Interestingly, this still works when using it as a shared library.
 */
extern __declspec(dllexport) struct objc_abi_class _NSConcreteStackBlock;
extern __declspec(dllexport) struct objc_abi_class _NSConcreteGlobalBlock;
extern __declspec(dllexport) void _Block_object_assign(void *, const void *,
    const int);
extern __declspec(dllexport) void _Block_object_dispose(const void *,
    const int);
# endif
#ifdef __cplusplus
}
#endif

#ifndef Block_copy
# define Block_copy(...) \
    ((__typeof__(__VA_ARGS__))_Block_copy((const void *)(__VA_ARGS__)))
#endif
#ifndef Block_release
# define Block_release(...) _Block_release((const void *)(__VA_ARGS__))
#endif

OF_ASSUME_NONNULL_END
