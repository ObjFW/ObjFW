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

#include <errno.h>

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No thread-local storage available!
#endif

#import "macros.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_key_t OFTLSKey;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef DWORD OFTLSKey;
#elif defined(OF_MORPHOS)
# include <proto/exec.h>
typedef ULONG OFTLSKey;
#elif defined(OF_AMIGAOS)
typedef struct _OFTLSKey {
	struct objc_hashtable *table;
	struct _OFTLSKey *next, *previous;
} *OFTLSKey;
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern int OFTLSKeyNew(OFTLSKey *key);
extern int OFTLSKeyFree(OFTLSKey key);
#ifdef __cplusplus
}
#endif

/* TLS keys are inlined for performance. */

#if defined(OF_HAVE_PTHREADS)
static OF_INLINE void *
OFTLSKeyGet(OFTLSKey key)
{
	return pthread_getspecific(key);
}

static OF_INLINE int
OFTLSKeySet(OFTLSKey key, void *ptr)
{
	return pthread_setspecific(key, ptr);
}
#elif defined(OF_WINDOWS)
static OF_INLINE void *
OFTLSKeyGet(OFTLSKey key)
{
	return TlsGetValue(key);
}

static OF_INLINE int
OFTLSKeySet(OFTLSKey key, void *ptr)
{
	return (TlsSetValue(key, ptr) ? 0 : EINVAL);
}
#elif defined(OF_MORPHOS)
static OF_INLINE void *
OFTLSKeyGet(OFTLSKey key)
{
	return (void *)TLSGetValue(key);
}

static OF_INLINE int
OFTLSKeySet(OFTLSKey key, void *ptr)
{
	return (TLSSetValue(key, (APTR)ptr) ? 0 : EINVAL);
}
#elif defined(OF_AMIGAOS)
/* Those are too big too inline. */
# ifdef __cplusplus
extern "C" {
# endif
extern void *OFTLSKeyGet(OFTLSKey key);
extern int OFTLSKeySet(OFTLSKey key, void *ptr);
# ifdef __cplusplus
}
# endif
#endif
