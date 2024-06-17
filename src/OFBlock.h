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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBlock OFBlock.h ObjFW/ObjFW.h
 *
 * @brief The class for all blocks, since all blocks are also objects.
 */
@interface OFBlock: OFObject
+ (instancetype)alloc OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;
@end

OF_SUBCLASSING_RESTRICTED
@interface OFStackBlock: OFBlock
@end

OF_SUBCLASSING_RESTRICTED
@interface OFGlobalBlock: OFBlock
@end

OF_SUBCLASSING_RESTRICTED
@interface OFMallocBlock: OFBlock
@end

#ifdef __cplusplus
extern "C" {
#endif
extern void *_Nullable _Block_copy(const void *_Nullable);
extern void _Block_release(const void *_Nullable);

# if defined(OF_WINDOWS) && \
    (defined(OF_NO_SHARED) || defined(OF_COMPILING_OBJFW))
/*
 * Clang has implicit declarations for these, but they are dllimport. When
 * compiling ObjFW itself or using it as a static library, these need to be
 * dllexport. Interestingly, this still works when using it as a shared library.
 */
extern __declspec(dllexport) struct objc_class _NSConcreteStackBlock;
extern __declspec(dllexport) struct objc_class _NSConcreteGlobalBlock;
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
