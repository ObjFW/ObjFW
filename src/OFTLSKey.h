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

/** @file */

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
/**
 * @brief Creates a new Thread Local Storage key.
 *
 * @param key A pointer to the key to create
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFTLSKeyNew(OFTLSKey *key);

/**
 * @brief Destroys the specified Thread Local Storage key.
 *
 * @param key A pointer to the key to destroy
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFTLSKeyFree(OFTLSKey key);
#ifdef __cplusplus
}
#endif

/* TLS keys are inlined for performance. */

#if defined(OF_HAVE_PTHREADS) || defined(DOXYGEN)
/**
 * @brief Returns the current value for the specified Thread Local Storage key.
 *
 * @param key A pointer to the key whose value to return
 * @return The current value for the specified Thread Local Storage key
 */
static OF_INLINE void *
OFTLSKeyGet(OFTLSKey key)
{
	return pthread_getspecific(key);
}

/**
 * @brief Sets the current value for the specified Thread Local Storage key.
 *
 * @param key A pointer to the key whose value to set
 * @param value The new value for the key
 */
static OF_INLINE int
OFTLSKeySet(OFTLSKey key, void *value)
{
	return pthread_setspecific(key, value);
}
#elif defined(OF_WINDOWS)
static OF_INLINE void *
OFTLSKeyGet(OFTLSKey key)
{
	return TlsGetValue(key);
}

static OF_INLINE int
OFTLSKeySet(OFTLSKey key, void *value)
{
	return (TlsSetValue(key, value) ? 0 : EINVAL);
}
#elif defined(OF_MORPHOS)
static OF_INLINE void *
OFTLSKeyGet(OFTLSKey key)
{
	return (void *)TLSGetValue(key);
}

static OF_INLINE int
OFTLSKeySet(OFTLSKey key, void *value)
{
	return (TLSSetValue(key, (APTR)value) ? 0 : EINVAL);
}
#elif defined(OF_AMIGAOS)
/* Those are too big too inline. */
# ifdef __cplusplus
extern "C" {
# endif
extern void *OFTLSKeyGet(OFTLSKey key);
extern int OFTLSKeySet(OFTLSKey key, void *value);
# ifdef __cplusplus
}
# endif
#endif
