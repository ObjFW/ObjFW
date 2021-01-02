/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include "objfw-defs.h"

#include <errno.h>

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No thread-local storage available!
#endif

#import "macros.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_key_t of_tlskey_t;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef DWORD of_tlskey_t;
#elif defined(OF_MORPHOS)
# include <proto/exec.h>
typedef ULONG of_tlskey_t;
#elif defined(OF_AMIGAOS)
typedef struct of_tlskey {
	struct objc_hashtable *table;
	struct of_tlskey *next, *previous;
} *of_tlskey_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern int of_tlskey_new(of_tlskey_t *key);
extern int of_tlskey_free(of_tlskey_t key);
#ifdef __cplusplus
}
#endif

/* TLS keys are inlined for performance. */

#if defined(OF_HAVE_PTHREADS)
static OF_INLINE void *
of_tlskey_get(of_tlskey_t key)
{
	return pthread_getspecific(key);
}

static OF_INLINE int
of_tlskey_set(of_tlskey_t key, void *ptr)
{
	return pthread_setspecific(key, ptr);
}
#elif defined(OF_WINDOWS)
static OF_INLINE void *
of_tlskey_get(of_tlskey_t key)
{
	return TlsGetValue(key);
}

static OF_INLINE int
of_tlskey_set(of_tlskey_t key, void *ptr)
{
	return (TlsSetValue(key, ptr) ? 0 : EINVAL);
}
#elif defined(OF_MORPHOS)
static OF_INLINE void *
of_tlskey_get(of_tlskey_t key)
{
	return (void *)TLSGetValue(key);
}

static OF_INLINE int
of_tlskey_set(of_tlskey_t key, void *ptr)
{
	return (TLSSetValue(key, (APTR)ptr) ? 0 : EINVAL);
}
#elif defined(OF_AMIGAOS)
/* Those are too big too inline. */
# ifdef __cplusplus
extern "C" {
# endif
extern void *of_tlskey_get(of_tlskey_t key);
extern int of_tlskey_set(of_tlskey_t key, void *ptr);
# ifdef __cplusplus
}
# endif
#endif
