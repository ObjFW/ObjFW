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

#include "objfw-defs.h"

#import "macros.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_once_t OFOnceControl;
# define OFOnceControlInitValue PTHREAD_ONCE_INIT
#elif defined(OF_HAVE_ATOMIC_OPS)
typedef volatile int OFOnceControl;
# define OFOnceControlInitValue 0
#elif defined(OF_AMIGAOS) || !defined(OF_HAVE_THREADS)
typedef int OFOnceControl;
# define OFOnceControlInitValue 0
#endif

OF_ASSUME_NONNULL_BEGIN

/** @file */

typedef void (*OFOnceFunction)(void);

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Executes the specified function exactly once in the application's
 *	  lifetime, even in a multi-threaded environment.
 *
 * @param control An OFOnceControl. This should be a static variable
 *		  preinitialized to `OFOnceControlInitValue`.
 * @param function The function to execute once
 */
extern void OFOnce(OFOnceControl *control, OFOnceFunction function);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
